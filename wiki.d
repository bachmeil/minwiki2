import arsd.cgi;
import minwiki.replacelinks, minwiki.staticsite;
import dmarkdown.markdown;
import std.file, std.path, std.process, std.regex, std.stdio;

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
		data = mdToHtml(readText(setExtension(name, "md")) ~ "\n\n" ~ `<br><a href="/"><u>&#171; Index</u></a>`, name);
	}
	else if (cgi.pathInfo == "/tag") {
		string tagname = cgi.get["tagname"];
		data = plainHtml("<h1>Tag: " ~ tagname ~ "</h1>\n" ~ fileLinks(executeShell(`grep -Rl '#` ~ tagname ~ `'`).output));
	}
	else if (cgi.pathInfo == "/backlinks") {
		string pagename = cgi.get["pagename"];
		string cmd = `grep -Rl '\[#` ~ pagename ~ `\]'`;
		data = plainHtml(`<h1>Backlinks: <a href="viewpage?name=` ~ pagename ~ `">` ~ pagename ~ "</a></h1>\n" ~ fileLinks(executeShell(cmd).output) ~ "<hr><br>" ~ mdToHtml(readText(pagename ~ ".md"), pagename) ~ "<hr><br><br>");
	}
	else if (cgi.pathInfo == "/save") {
		string name = cgi.get["name"];
		std.file.write(setExtension(name, "html"), htmlPage(readText(setExtension(name, "md")), name));
		cgi.setResponseLocation("/viewpage?name=" ~ name);
	}
	else if (cgi.pathInfo == "/staticsite") {
		string[][string] tags;
		foreach(f; listmd()) {
			string pagename = stripExtension(f);
			string txt = readText(setExtension(f, "md"));
			string cmd = `grep -Rl '\[#` ~ pagename ~ `\]'`;
			string bl = "<h3 style='font-size: 89%;'>Backlinks</h3>\n" ~ fileLinks(executeShell(cmd).output) ~ "<br><br><br>";
			std.file.write(setExtension(f, "html"), htmlPage(txt, f) ~ bl);
			auto tagMatches = txt.matchAll(regex(`(?<=^|<br>|\s)(#)([a-zA-Z][a-zA-Z0-9]*?)(?=<br>|\s|$)`, "m"));
			foreach(tag; tagMatches) {
				string taghit = tag.hit[1..$];
				if (taghit in tags) {
					tags[taghit] ~= stripExtension(baseName(f));
				} else {
					tags[taghit] = [stripExtension(baseName(f))];
				}
			}
		}
		std.file.write("tags.html", tagsBody(tags));
		data = `HTML files written to disk<br><br><a href="/">Index</a>`;
	}
	else if (cgi.pathInfo == "/bookmark") {
		string url = cgi.get["url"];
		string desc = cgi.get["desc"];
		std.file.append("links.md", "\n- [" ~ desc ~ "](" ~ url ~ ")");
		data = "Added " ~ url ~ ": " ~ desc ~ " to the links file.";
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

string mdToHtml(string s, string name) {
	string mdfile = changeLinks(`<a href="/">&#10070; Home</a>&nbsp;&nbsp;&nbsp;<a href="editpage?name=` ~ name ~ `">&#9998; Edit</a>&nbsp;&nbsp;&nbsp;<a href="backlinks?pagename=` ~ name ~ `">&#10149; Backlinks</a>&nbsp;&nbsp;&nbsp;<a href="save?name=` ~ name ~ `">&#8681; Save As HTML</a><br><br>` ~ "\n\n" ~ s);
	return plaincss ~ mdfile.filterMarkdown(_mdflags);
}

string htmlPage(string s, string name) {
	string mdfile = staticLinks(`<a href="index.html">&#10070; Home</a><br><br>` ~ "\n\n" ~ s);
	return plaincss ~ mdfile.filterMarkdown(_mdflags);
}

string plainHtml(string s) {
	return plaincss ~ s.filterMarkdown(_mdflags);
}

string[] listmd() {
    import std.algorithm, std.array;
    return std.file.dirEntries(".", SpanMode.shallow)
        .filter!(a => a.isFile)
        .filter!(a => extension(a) == ".md")
        .map!(a => std.path.baseName(a.name))
        .array
        .sort!"a < b"
        .array;
}

string tagsBody(string[][string] tags) {
	string result = `<body onhashchange="displaytag();">
`;
	foreach(tag; tags.keys) {
		result ~= `<div id='` ~ tag ~ `' class='tag'>
<h1>Tag: ` ~ tag ~ `</h1>
`;
		foreach(file; tags[tag]) {
			result ~= `<a href="` ~ setExtension(file, "html") ~ `">` ~ stripExtension(file) ~ "</a>\n<br>";
		}
		result ~= "</div>";
	}
	return result ~ `</body>
<script>function displaytag() {
	for (el of document.getElementsByClassName('tag')) {
		el.style = 'display: none;';
	}
	document.getElementById(location.hash.substr(1)).style.display = "inline";
}
displaytag();
</script>`;
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
