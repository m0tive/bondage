COPYRIGHT_MESSAGE = "Copyright me, fool. No, copying and stuff."
AUTOGEN_MESSAGE = "This file is auto generated, do not change it!"

def writePreamble(file, lineStart)
	file.write(
"#{lineStart} #{COPYRIGHT_MESSAGE}
#{lineStart}		
#{lineStart} #{AUTOGEN_MESSAGE}
#{lineStart}

")
end
