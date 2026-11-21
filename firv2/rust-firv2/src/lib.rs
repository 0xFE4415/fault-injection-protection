use std::sync::atomic;

use proc_macro::{Span, TokenStream};
use quote::ToTokens;
use syn::visit_mut::VisitMut;
use syn::{Attribute, ItemFn, ReturnType};

static IDX: atomic::AtomicUsize = atomic::AtomicUsize::new(0);

fn no_inline_attr() -> Attribute {
    syn::parse_quote! {
        #[inline(never)]
    }
}

struct ElideLifetimes {
    outer_lifetimes: Vec<syn::Ident>,
}

impl VisitMut for ElideLifetimes {
    fn visit_lifetime_mut(&mut self, lifetime: &mut syn::Lifetime) {
        if self.outer_lifetimes.contains(&lifetime.ident) {
            *lifetime = syn::Lifetime::new("'_", lifetime.span());
        }
    }
}

fn elide_outer_lifetimes(return_type: &syn::Type, generics: &syn::Generics) -> syn::Type {
    let mut elide_lifetimes = ElideLifetimes {
        outer_lifetimes: Vec::new(),
    };
    for lifetime_param in generics.lifetimes() {
        elide_lifetimes
            .outer_lifetimes
            .push(lifetime_param.lifetime.ident.clone());
    }
    let mut elided_type = return_type.clone();
    elide_lifetimes.visit_type_mut(&mut elided_type);
    elided_type
}

fn insert_eq_function(item_fn: &mut ItemFn, user_eq_name: &str, function_name: &str) {
    let eq_function_name = syn::Ident::new(function_name, Span::call_site().into());
    let user_eq_name: syn::ExprPath =
        syn::parse_str(user_eq_name).expect("expected ExprPath, e.g. i32::eq");

    let return_type = match &item_fn.sig.output {
        ReturnType::Type(_, t) => t,
        _ => panic!("Function must have a return type"),
    };

    item_fn.sig.inputs.iter().for_each(|arg| {
        let is_shared_ref = match arg {
            syn::FnArg::Typed(p) => {
                matches!(&*p.ty, syn::Type::Reference(r) if r.mutability.is_none())
            }
            syn::FnArg::Receiver(p) => p.reference.is_some() && p.mutability.is_none(),
        };
        assert!(
            is_shared_ref,
            "arg: {:?} must be a shared reference",
            arg.to_token_stream().to_string()
        );
    });

    let return_type = elide_outer_lifetimes(return_type, &item_fn.sig.generics);
    item_fn.block.stmts.insert(
        0,
        syn::parse_quote! {
                // eq function
                #[inline(never)]
                pub fn #eq_function_name(x : & #return_type , y: & #return_type) -> bool {
                    return #user_eq_name(&x, &y);
                }
        },
    );
}

fn insert_identifier_function(item_fn: &mut ItemFn, function_name: &str) {
    let identifier_function_name = syn::Ident::new(function_name, Span::call_site().into());
    item_fn.block.stmts.insert(
        0,
        syn::parse_quote! {
        extern "C" {
            // identifier function
            pub fn #identifier_function_name(eq_function: *const (), hardened_function: *const ());
        }
        },
    );
}
fn insert_identifier_call(item_fn: &mut ItemFn, function_name: &str, eq_function_name: &str) {
    let identifier_function_name = syn::Ident::new(function_name, Span::call_site().into());
    let eq_function_name = syn::Ident::new(eq_function_name, Span::call_site().into());
    let hardened_function_name = item_fn.sig.ident.clone();
    item_fn.block.stmts.insert(
        0,
        syn::parse_quote! {
            {
                // Call the identifier function so that we can find function to
                // harden
                unsafe {#identifier_function_name(#eq_function_name as *const (), #hardened_function_name as *const ())}
            };
        },
    );
}

#[proc_macro_attribute]
pub fn harden_fn(attr: TokenStream, item: TokenStream) -> TokenStream {
    let mut item_fn = syn::parse_macro_input!(item as syn::ItemFn);
    let user_eq_name = attr.to_string();
    let function_name_prefix = format!(
        "internal_firv2_{}_",
        IDX.fetch_add(1, atomic::Ordering::SeqCst)
    );
    item_fn.attrs.push(no_inline_attr());
    let identifier_function_name = format!("{function_name_prefix}identifier");
    let eq_fn = format!("{function_name_prefix}eq");

    insert_identifier_function(&mut item_fn, &identifier_function_name);
    insert_eq_function(&mut item_fn, &user_eq_name, &eq_fn);
    insert_identifier_call(&mut item_fn, &identifier_function_name, &eq_fn);

    item_fn.to_token_stream().into()
}
