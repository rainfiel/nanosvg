
local action = _ACTION or ""

solution "nanosvg"
	location ( "build" )
	configurations { "Debug", "Release" }
	platforms {"native", "x64", "x32"}
  

	project "example2"
		kind "ConsoleApp"
		language "C++"
		files { "example/example2.c", "example/*.h", "src/*.h" }
		includedirs { "example", "src" }
		targetdir("build")
	 
		configuration { "linux" }
			 links { "X11","Xrandr", "rt", "pthread" }

		configuration { "windows" }
			 links { "winmm", "user32" }

		configuration { "macosx" }
			linkoptions { "-framework Cocoa", "-framework IOKit" }

		configuration "Debug"
			defines { "DEBUG" }
			flags { "Symbols", "ExtraWarnings"}

		configuration "Release"
			defines { "NDEBUG" }
			flags { "Optimize", "ExtraWarnings"}    
