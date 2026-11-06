import Lake
open Lake DSL

package LdhUploads where
  -- ld64 in the pinned toolchain emits a __DATA_CONST segment that dyld on macOS 26 and later refuses to load
  -- ("missing SG_READ_ONLY flag"); not creating the segment sidesteps it. GNU ld knows no such flag
  moreLinkArgs := if System.Platform.isOSX then #["-Wl,-no_data_const"] else #[]

/-- The graph store: an upload is committed by its writes and described by its graphs. -/
require LdhHttp from "../http"

@[default_target]
lean_lib LdhUploads

/-- The serving model's answers, for the HTTP suite to replay: see `Main.lean`. -/
@[default_target]
lean_exe «ldh-uploads» where
  root := `Main
