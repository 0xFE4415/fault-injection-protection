use std::collections::HashSet;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::sync::atomic;

use proc_macro::{Span, TokenStream};
use quote::ToTokens;
use syn::punctuated::Punctuated;
use syn::visit_mut::{self, VisitMut};

static IDX: atomic::AtomicUsize = atomic::AtomicUsize::new(0);

struct HardenVariable {
    requested: HashSet<String>,
    hardened: HashSet<String>,
    call_site: Span,
}
impl HardenVariable {
    fn new(requested: Vec<String>, call_site: Span) -> Self {
        Self {
            requested: requested.into_iter().collect(),
            hardened: HashSet::new(),
            call_site,
        }
    }
    fn check(self) -> Result<(), HashSet<String>> {
        let not_hardened: HashSet<String> =
            self.requested.difference(&self.hardened).cloned().collect();
        if not_hardened.is_empty() {
            Ok(())
        } else {
            Err(not_hardened)
        }
    }
    fn harden_local(&mut self, stmt: &mut syn::Local) {
        let syn::Pat::Type(syn::PatType { pat, ty, .. }) = &stmt.pat else {
            return;
        };
        let syn::Pat::Ident(pattern) = &**pat else {
            return;
        };
        let harden_var_name = &pattern.ident;
        if !self.requested.contains(&harden_var_name.to_string()) {
            return;
        }
        self.hardened.insert(harden_var_name.to_string());
        let Some(original_init) = &mut stmt.init else {
            panic!(
                "Failed to harden variable: {:?}, because it was not initialized.",
                harden_var_name
            );
        };

        harden_init(original_init, ty, marker_name(&self.call_site, ty));
    }
}

// LTO merges same-named declarations of all crates, so the name must differ
// between crates and between types
fn marker_name(call_site: &Span, ty: &syn::Type) -> syn::Ident {
    let mut hasher = DefaultHasher::new();
    std::env::var("CARGO_CRATE_NAME").ok().hash(&mut hasher);
    call_site.file().hash(&mut hasher);
    call_site.line().hash(&mut hasher);
    call_site.column().hash(&mut hasher);
    ty.to_token_stream().to_string().hash(&mut hasher);
    IDX.fetch_add(1, atomic::Ordering::SeqCst).hash(&mut hasher);
    syn::Ident::new(
        &format!("cfip_harden_var_{:016x}", hasher.finish()),
        Span::call_site().into(),
    )
}

fn harden_init(stmt_init: &mut syn::LocalInit, ty: &Box<syn::Type>, function_name: syn::Ident) {
    let new_init = stmt_init.expr.to_token_stream();

    *stmt_init = syn::LocalInit {
        expr: Box::<syn::Expr>::new(
            syn::parse(
                quote::quote! {
                    {
                        unsafe extern "C" {
                            // this function does not actually exist
                            #[allow(improper_ctypes)]
                            fn #function_name(dummy: #ty) -> #ty;
                        }
                        unsafe { #function_name( #new_init ) }
                    }
                }
                .into(),
            )
            .expect("Failed to insert hidden_call block"),
        ),
        ..stmt_init.clone()
    };
}
impl VisitMut for HardenVariable {
    fn visit_local_mut(&mut self, stmt: &mut syn::Local) {
        visit_mut::visit_local_mut(self, stmt);
        self.harden_local(stmt);
    }
}

#[proc_macro_attribute]
pub fn harden_vars_fn(attr: TokenStream, item: TokenStream) -> TokenStream {
    let requested_names = syn::parse_macro_input!(attr with Punctuated::<syn::Ident, syn::Token![,]>::parse_terminated);
    let requested = requested_names
        .iter()
        .map(|name| name.to_string())
        .collect();
    let mut harden = HardenVariable::new(requested, Span::call_site());
    let mut item_fn = syn::parse_macro_input!(item as syn::ItemFn);
    harden.visit_item_fn_mut(&mut item_fn);
    harden.check().unwrap_or_else(|not_hardened| {
        panic!("Failed harden requested variables: {:?}.", not_hardened)
    });
    item_fn.to_token_stream().into()
}
