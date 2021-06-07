import arsd.cgi, arsd.web;
import minwiki.replacelinks, minwiki.tem;
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
enum _editor = "pluma ";

// Change markdown parsing options here
MarkdownFlags	_mdflags = MarkdownFlags.backtickCodeBlocks|MarkdownFlags.disableUnderscoreEmphasis;

/*
 * Converts text into a web page. Functions should return an Element.
 */
Element toHtml(string s) {
	writeln("inside toHtml...");
	auto d = new Document();
	writeln("create fragment...");
	Element f = d.createFragment();
	f.innerHTML = s;
	writeln("done making html...");
	return f;
}

/*
 * Load a page in the browser.
 * Converts links to the proper html form.
 * Supports Pandoc-style line breaks.
 * 
 * You can set markdown flags (as found in markdown.d) in here.
 */
Element renderPage(string name) {
	writeln("rendering...");
	string f = readText(name ~ ".md").strip;
	string mdfile = changeLinks(`<a href="editpage?name=` ~ name ~ `">[Edit This Page]</a> <a href="backlinks?pagename=` ~ name ~ `">[Backlinks]</a><br><br>` ~ "\n\n" ~ f);
	writeln("off to toHtml...");
	writeln(mdfile.filterMarkdown(_mdflags).replace("<br />", "<br>").toHtml());
	return mdfile.filterMarkdown(_mdflags).replace("<br />", "<br>").toHtml();
}

string mdToHtml(string s, string name) {
	string mdfile = changeLinks(`<a href="editpage?name=` ~ name ~ `">[Edit This Page]</a> <a href="backlinks?pagename=` ~ name ~ `">[Backlinks]</a><br><br>` ~ "\n\n" ~ s);
	return mdfile.filterMarkdown(_mdflags);
}

/*
 * Not used, but included in case you want to run a shell
 * command and return the output as a page.
 */
Element shellOutput(string cmd) {
	return toHtml(executeShell(cmd).output);
}

//class Test: ApiProvider {
class Test: Wikisite {
	export Element viewpage(string name) {
		writeln("viewpage...");
		// Note: This does a check for the existence of the directory
		// Only creates it if it doesn't exist
		mkdirRecurse(std.path.dirName(name));			
		if (!exists(name ~ ".md")) {
			executeShell(_editor ~ " " ~ name ~ ".md");
		}
		writeln("going to render...");
		return renderPage(name);
	}
	
	export Element editpage(string name) {
		executeShell(_editor ~ " " ~ name ~ ".md");
		cgi.setResponseLocation("viewpage?name=" ~ name);
		return renderPage(name);
	}

	export Element tag(string tagname) {
		return toHtml("<h1>Tag: " ~ tagname ~ "</h1>\n" ~ fileLinks(executeShell(`grep -Rl '#` ~ tagname ~ `'`).output));
	}

	export Element backlinks(string pagename) {
		string cmd = `grep -Rl '\[#` ~ pagename ~ `\]'`;
		writeln(cmd);
		return toHtml(`<h1>Backlinks: <a href="viewpage?name=` ~ pagename ~ `">` ~ pagename ~ "</a></h1>\n" ~ fileLinks(executeShell(cmd).output) ~ "<br><hr>" ~ mdToHtml(readText(pagename ~ ".md"), pagename) ~ "<hr><br><br>");
	}
	
	export Element index() {
		writeln("in the index...");
		if (!exists("index.md")) {
			std.file.write("index.md", "# Index Page\n\nThis is the starting point for your wiki. Click the link above to edit.");
		}
		return viewpage("index");
	}
}
mixin FancyMain!Test;

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
