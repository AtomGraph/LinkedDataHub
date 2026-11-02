import Lake
open Lake DSL

package LdhAcl where
  -- ld64 in the pinned toolchain emits a __DATA_CONST segment that dyld on macOS 26 and later refuses to load
  -- ("missing SG_READ_ONLY flag"); not creating the segment sidesteps it. GNU ld knows no such flag
  moreLinkArgs := if System.Platform.isOSX then #["-Wl,-no_data_const"] else #[]

/-- The graph store: the authorization decision is modelled over its data and its writes. -/
require LdhHttp from "../http"

@[default_target]
lean_lib LdhAcl

/-- The decision, and the server's answer behind it, over a live instance's datasets: see `Main.lean`. -/
@[default_target]
lean_exe «ldh-acl» where
  root := `Main
