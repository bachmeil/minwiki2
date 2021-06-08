import arsd.cgi;
import minwiki.replacelinks;
import dmarkdown.markdown;
import std.file, std.path, std.process, std.stdio;

/*
 * Set the text editor used to edit/create pages.
 * The `-i` option tells Geany to open a new editor.
 * When you edit a page, the web server will wait until the editor
 * is closed before it continues. If you open the file in
 * an already running editor, you'll have to close that editor
 * before you can continue.
 */
enum _editor = "geany -i";

// Change markdown parsing options here
MarkdownFlags	_mdflags = MarkdownFlags.backtickCodeBlocks|MarkdownFlags.disableUnderscoreEmphasis;

string mdToHtml(string s, string name) {
	string mdfile = changeLinks(`<a href="editpage?name=` ~ name ~ `">[Edit]</a> <a href="backlinks?pagename=` ~ name ~ `">[Backlinks]</a><br><br>` ~ "\n\n" ~ s);
	return plaincss ~ mdfile.filterMarkdown(_mdflags);
}

string plainHtml(string s) {
	return plaincss ~ s.filterMarkdown(_mdflags);
}

void hello(Cgi cgi) {
	string data;
	if (cgi.pathInfo == "/") {
		if (!exists("index.md")) {
			std.file.write("index.md", "# Index Page\n\nThis is the starting point for your wiki. Click the link above to edit.");
		}
		data = mdToHtml(readText("index.md"), "index");
	}
	else if (cgi.pathInfo == "/editpage") {
		string name = cgi.get["name"];
		executeShell(_editor ~ " " ~ setExtension(name, "md"));
		cgi.setResponseLocation("viewpage?name=" ~ name);
		data = mdToHtml(readText(setExtension(name, "md")), name);
	}
	else if (cgi.pathInfo == "/viewpage") {
		string name = cgi.get["name"];
		mkdirRecurse(std.path.dirName(name));			
		if (!exists(setExtension(name, "md"))) {
			executeShell(_editor ~ " " ~ setExtension(name, "md"));
		}
		data = mdToHtml(readText(setExtension(name, "md")) ~ `<br><br><a href="/"><u>&#171; Index</u></a>`, name);
	}
	else if (cgi.pathInfo == "/tag") {
		string tagname = cgi.get["tagname"];
		data = plainHtml("<h1>Tag: " ~ tagname ~ "</h1>\n" ~ fileLinks(executeShell(`grep -Rl '#` ~ tagname ~ `'`).output));
	}
	else if (cgi.pathInfo == "/backlinks") {
		string pagename = cgi.get["pagename"];
		string cmd = `grep -Rl '\[#` ~ pagename ~ `\]'`;
		data = plainHtml(`<h1>Backlinks: <a href="viewpage?name=` ~ pagename ~ `">` ~ pagename ~ "</a></h1>\n" ~ fileLinks(executeShell(cmd).output) ~ "<br><hr>" ~ mdToHtml(readText(pagename ~ ".md"), pagename) ~ "<hr><br><br>");
	}
	cgi.write(data, true);
}
mixin GenericMain!hello;

string fileLinks(string output) {
	if (output.length == 0) {
		return "";
	} else {
		string result;
		string[] files = output.split("\n");
		foreach(file; files) {
			if (file.length > 0) {
				result ~= `<a href="viewpage?name=` ~ stripExtension(file) ~ `">` ~ stripExtension(file) ~ "<a><br>\n";
			}
		}
		return result;
	}
}

enum plaincss = `<style>
body { margin: auto; max-width: 800px; font-size: 120%; margin-top: 20px; }
a { text-decoration: none; }
pre > code {
  padding: .2rem .5rem;
  margin: 0 .2rem;
  font-size: 90%;
  white-space: nowrap;
  background: #F1F1F1;
  border: 1px solid #E1E1E1;
  border-radius: 4px; 
  display: block;
  padding: 1rem 1.5rem;
  white-space: pre; 
}
h1, h2, h3 { font-family: sans; font-size: 140%; }
</style>`;
