run: love
	love dist/sokoban.love

love:
	rm -rf sokoban.love
	zip -r dist/sokoban.love assets gamestates levels lib *.lua
