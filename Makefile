run: love
	love dist/sokoban.love

love:
	rm -rf sokoban.love
	zip -r dist/sokoban.love assets gamestates levels lib *.lua

ios:
	mv conf.lua conf.default.lua
	mv conf.mobile.lua conf.lua
	$(MAKE) love

	mv conf.lua conf.mobile.lua
	mv conf.default.lua conf.lua

mac: love
	mv dist/sokoban.love dist/macos/Sokoban.app/Contents/Resources/sokoban.love
	cd dist/macos && zip -r sokoban-app-OSX.zip *
	mv dist/macos/sokoban-app-OSX.zip dist/
	rm -fr dist/macos/Sokoban.app/Contents/Resources/sokoban.love

windows:
	mv conf.lua conf.default.lua
	mv conf.windows.lua conf.lua

	$(MAKE) love

	mv conf.lua conf.windows.lua
	mv conf.default.lua conf.lua

	cd dist/windows && cat love.exe ../sokoban.love > Sokoban.exe
	cd dist/windows && zip -r sokoban-WIN.zip *
	mv dist/windows/sokoban-WIN.zip dist/
	rm -fr dist/sokoban.love
	rm -fr dist/windows/Sokoban.exe
