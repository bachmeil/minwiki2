import arsd.cgi;
//~ import minwiki.replacelinks, minwiki.staticsite;
//~ import dmarkdown.markdown;
import commonmarkd;
import commonmarkd.md4c;
import std.datetime, std.file, std.path, std.process, std.stdio, std.uri;

/*
 * Set the text editor used to edit/create pages.
 * The `-i` option tells Geany to open a new editor.
 * When you edit a page, the web server will wait until the editor
 * is closed before it continues. If you open the file in
 * an already running editor, you'll have to close that editor
 * before you can continue.
 */
enum _editor = "geany -i";

void hello(Cgi cgi) {
	string data;
  auto pi = cgi.pathInfo.decode;
  writeln("pi: ", pi);
	if ( (pi == "/") | (pi == "/index") ) {
		if (!exists("index.md")) {
			std.file.write("index.md", "# Index Page\n\nThis is the starting point for your wiki. Click the link above to edit.");
		}
    cgi.setResponseLocation("/wiki/index");
	}
	else if (pi.startsWith("/edit/")) {
		string name = pi[6..$];
    string filename = setExtension(name, "md");
    if (exists(filename)) {
      data = readText("edittemplate.html")
        .replace("<Put note name here>", name)
        .replace("<Put note content here>", 
          readText(filename).replace("`", "\\`"));
    } else {
      data = readText("edittemplate.html")
        .replace("<Put note name here>", name)
        .replace("<Put note content here>", "");
    }
	}
  else if (pi == "/updatenote") {
    auto notename = cgi.post["notename"];
    auto content = cgi.post.get("content", "No field named content");
    writeln("Note name: ", notename);
    std.file.write(setExtension(notename, "md"), content);
    cgi.setResponseLocation("/wiki/" ~ notename);
  }
  else if (pi == "/form") {
    data = readText("easymdetest.html");
  /* You can use a wiki link *inside* the link
   * If it is [[link]] it will treat it as a wiki link.
   * This keeps the traditional wiki link syntax without
   * requiring a different markdown parser. It also prevents
   * issues with the URL if you forget to make wiki links absolute. 
   * Another option would be to cut off anything before /wiki/, but
   * that would prevent the use of directories named wiki. 
   * 
   * Example: [How to make a million dollars a day]([[fraud/crackpot]]) */
  }
  else if (pi.endsWith("]]")) {
    auto ind = pi.lastIndexOf("[[") + 2;
    string name = pi[ind..$-2];
    cgi.setResponseLocation("/wiki/" ~ name);
  }
	else if (pi.startsWith("/wiki/")) {
		string name = pi[6..$];
		if (!exists(setExtension(name, "md"))) {
      mkdirRecurse(std.path.dirName(name));
			executeShell(_editor ~ " " ~ setExtension(name, "md"));
		}
		data = readText(setExtension(name, "md")).wikipageHtml(name);
	}
  else if (cgi.pathInfo == "/monthly") {
    SysTime ct = Clock.currTime();
    string m = ct.toISOString()[0..6];
    string fn = "monthly/" ~ m[0..4] ~ "-" ~ m[4..6];
		if (!exists(fn)) {
      mkdirRecurse(std.path.dirName("monthly"));
		}
    cgi.setResponseLocation("/wiki/" ~ fn);
  }
  else if (pi.startsWith("/monthly-")) {
  }
  else if (pi.startsWith("/monthly+")) {
  }
  else if (pi == "/fullindex") {
    data = pageIndex();
  }
  else if (pi == "/push") {
    data = executeShell("git add .;git commit -am 'nm';git pull;git push").output;
  }
  /* This is nice, but put it in dlangdb rather than this format */
	//~ else if (cgi.pathInfo == "/bookmark") {
		//~ string url = cgi.get["url"];
		//~ string desc = cgi.get["desc"];
		//~ std.file.append("links.md", "\n- [" ~ desc ~ "](" ~ url ~ ")");
		//~ data = "Added " ~ url ~ ": " ~ desc ~ " to the links file.";
	//~ }
  else {
    data = "Not sure how to handle that URL";
  }
	cgi.write(data, true);
}
mixin GenericMain!hello;

string toHtml(string s) {
  return readText("template/top.html").replace("<style>\n</style>", "<style>\n" ~ readText("template/style.css").strip ~ "\n</style>") 
    ~ convertMarkdownToHTML(s, MarkdownFlag.dialectCustom) ~ readText("template/bottom.html");
}

string wikipageHtml(string s, string name) {
  return readText("template/top.html").replace("<style>\n</style>", 
    "<style>\n" ~ readText("template/style.css").strip ~ "\n</style>\n")
    ~ `<div class="topmenu">`
    ~ `<a href="/">Home</a> `
    ~ `<a href="/fullindex">Wiki Index</a> `
    ~ `<a href="/monthly">This Month</a> `
    ~ `<a href="/edit/` ~ name ~ `">Edit</a>`
    ~ "</div>"
    ~ "<div class=\"content\">\n"
    ~ convertMarkdownToHTML(s, MarkdownFlag.dialectCustom) 
    ~ "\n</div>" 
    ~ readText("template/bottom.html");
}

string pageIndex() {
  string cleanFilename(string s) {
    if (s.startsWith("./")) { 
      return stripExtension(s[2..$]); 
    } else { 
      return stripExtension(s); 
    }
  }
  
  import std.algorithm;
  return readText("template/top.html").replace("<style>\n</style>", 
    "<style>\n" ~ std.string.strip(readText("template/style.css")) ~ "\n</style>\n")
    ~ `<div class="topmenu">`
    ~ `<a href="/">Home</a> `
    ~ `<a href="/monthly">This Month</a> `
    ~ "</div>"
    ~ "<div class=\"content\">\n"
    ~ convertMarkdownToHTML("# Index of all wiki pages\n\n- " 
        ~ listmd.map!(a => cleanFilename(a))
          .map!(a => "[" ~ a ~ "](/wiki/" ~ a ~ ")")
          .join("\n- "), MarkdownFlag.dialectCustom) 
    ~ "\n</div>" 
    ~ readText("template/bottom.html");
}

//~ string fileLinks(string output) {
	//~ if (output.length == 0) {
		//~ return "";
	//~ } else {
		//~ string result;
		//~ string[] files = output.split("\n");
		//~ foreach(file; files) {
			//~ if (file.length > 0) {
				//~ result ~= `<a href="viewpage?name=` ~ stripExtension(file) ~ `">` ~ stripExtension(file) ~ "<a><br>\n";
			//~ }
		//~ }
		//~ return result;
	//~ }
//~ }

//~ string mdToHtml(string s, string name) {
	//~ string mdfile = changeLinks(`<a href="/">&#10070; Home</a>&nbsp;&nbsp;&nbsp;<a href="editpage?name=` ~ name ~ `">&#9998; Edit</a>&nbsp;&nbsp;&nbsp;<a href="backlinks?pagename=` ~ name ~ `">&#10149; Backlinks</a>&nbsp;&nbsp;&nbsp;<a href="save?name=` ~ name ~ `">&#8681; Save As HTML</a><br><br>` ~ "\n\n" ~ s);
	//~ return plaincss ~ mdfile.filterMarkdown(_mdflags);
//~ }

//~ string htmlPage(string s, string name) {
	//~ string mdfile = staticLinks(`<a href="index.html">&#10070; Home</a><br><br>` ~ "\n\n" ~ s);
	//~ return plaincss ~ mdfile.filterMarkdown(_mdflags);
//~ }

//~ string plainHtml(string s) {
	//~ return plaincss ~ s.filterMarkdown(_mdflags);
//~ }

string[] listmd() {
    import std.algorithm, std.array;
    return std.file.dirEntries(".", "*.md", SpanMode.breadth)
        .filter!(a => a.isFile)
        .map!(a => a.name)
        .array
        .sort!"a < b"
        .array;
}

//~ string tagsBody(string[][string] tags) {
	//~ string result = `<body onhashchange="displaytag();">
//~ `;
	//~ foreach(tag; tags.keys) {
		//~ result ~= `<div id='` ~ tag ~ `' class='tag'>
//~ <h1>Tag: ` ~ tag ~ `</h1>
//~ `;
		//~ foreach(file; tags[tag]) {
			//~ result ~= `<a href="` ~ setExtension(file, "html") ~ `">` ~ stripExtension(file) ~ "</a>\n<br>";
		//~ }
		//~ result ~= "</div>";
	//~ }
	//~ return result ~ `</body>
//~ <script>function displaytag() {
	//~ for (el of document.getElementsByClassName('tag')) {
		//~ el.style = 'display: none;';
	//~ }
	//~ document.getElementById(location.hash.substr(1)).style.display = "inline";
//~ }
//~ displaytag();
//~ </script>`;
//~ }	

//~ enum plaincss = `<style>
//~ body { margin: auto; max-width: 800px; font-size: 120%; margin-top: 20px; }
//~ a { text-decoration: none; }
//~ pre > code {
  //~ padding: .2rem .5rem;
  //~ margin: 0 .2rem;
  //~ font-size: 90%;
  //~ white-space: nowrap;
  //~ background: #F1F1F1;
  //~ border: 1px solid #E1E1E1;
  //~ border-radius: 4px; 
  //~ display: block;
  //~ padding: 1rem 1.5rem;
  //~ white-space: pre; 
//~ }
//~ h1, h2, h3 { font-family: sans; font-size: 140%; }
//~ </style>`;
