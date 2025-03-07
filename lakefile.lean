import Lake
open Lake DSL

package «Poly» where
  -- Settings applied to both builds and interactive editing
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩ -- pretty-prints `fun a ↦ b`
  ]
  -- add any additional package configuration options here

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"

require seq from git "https://github.com/Vtec234/lean4-seq"

@[default_target]
lean_lib «Poly» where
  -- add any library configuration options here
