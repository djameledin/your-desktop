-- Function: Optimize system before running heavy operations
on optimizeSystem()
	-- Check desktop items count (heavy Finder loops avoided when empty)
	set desktopPath to POSIX path of (path to desktop folder)
	set desktopCount to (do shell script "ls -1 \"" & desktopPath & "\" | wc -l")
	
	-- Check if user-installed apps exist
	set userAppsCount to (do shell script "find /Users/*/Applications -maxdepth 1 -name \"*.app\" 2>/dev/null | wc -l")
	
	-- Return a record with results to decide execution
	return {desktopItems:desktopCount as integer, userApps:userAppsCount as integer}
end optimizeSystem


-- Function: Change macOS theme
on setTheme()
	set currentHour to (time of (current date)) div 3600
	
	tell application "System Events"
		tell appearance preferences
			if currentHour ≥ 18 or currentHour < 6 then
				if dark mode is false then set dark mode to true
			else
				if dark mode is true then set dark mode to false
			end if
		end tell
	end tell
end setTheme


-- Function: Clean desktop excluding certain folders
on cleanDesktop(excludedFolders)
	set userDesktop to (path to desktop folder)
	
	tell application "Finder"
		set desktopItems to every item of userDesktop
		
		repeat with itemRef in desktopItems
			set itemName to name of itemRef
			
			if excludedFolders does not contain itemName then
				move itemRef to trash
			end if
		end repeat
	end tell
end cleanDesktop


-- Function: Remove user-installed apps to shared folder
on removeUserApps()
	do shell script "mkdir -p /Users/Shared/RemovedApps"
	do shell script "
	for userAppDir in /Users/*/Applications; do
	  if [ -d \"$userAppDir\" ]; then
		for app in \"$userAppDir\"/*.app; do
		  if [ -e \"$app\" ]; then
			mv \"$app\" /Users/Shared/RemovedApps/
		  fi
		done
	  fi
	done
	" with administrator privileges
end removeUserApps


-- Function: Download & set wallpaper if not already exists
on setWallpaper(wallpaperURL, wallpaperPathPOSIX)
	set wallpaperFile to POSIX file wallpaperPathPOSIX
	
	tell application "Finder"
		try
			if not (exists file wallpaperFile) then
				do shell script "curl -L \"" & wallpaperURL & "\" -o " & wallpaperPathPOSIX
			end if
			
			set desktop picture to wallpaperFile
		end try
	end tell
end setWallpaper


-- Main Execution
set optimization to optimizeSystem()
setTheme()
if desktopItems of optimization > 0 then
	cleanDesktop({"Applications", "Utilities"})
end if
if userApps of optimization > 0 then
	removeUserApps()
end if
setWallpaper("https://microsoft.design/wp-content/uploads/2025/07/Brand-Flowers-Static-1.png", "/Users/Shared/wallpaper.png")
