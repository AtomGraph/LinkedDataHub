import Lake
open Lake DSL

package LdhAuth where
  -- ld64 in the pinned toolchain emits a __DATA_CONST segment that dyld on macOS 26 and later refuses to load
  -- ("missing SG_READ_ONLY flag"); not creating the segment sidesteps it. GNU ld knows no such flag
  moreLinkArgs := if System.Platform.isOSX then #["-Wl,-no_data_const"] else #[]

/-- The authorization decision: the agent established here is its input. -/
require LdhAcl from "../acl"

@[default_target]
lean_lib LdhAuth

/-- Authentication over WebID documents and a request's headers: see `Main.lean`. -/
@[default_target]
lean_exe «ldh-auth» where
  root := `Main
