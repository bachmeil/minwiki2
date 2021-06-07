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
enum _editor = "geany -i";

// Change markdown parsing options here
MarkdownFlags	_mdflags = MarkdownFlags.backtickCodeBlocks|MarkdownFlags.disableUnderscoreEmphasis;

/*
 * Converts text into a web page. Functions should return an Element.
 */
Element toHtml(string s) {
	auto d = new Document();
	Element f = d.createFragment();
	f.innerHTML = s;
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
	string f = readText(name ~ ".md").strip;
	string mdfile = changeLinks(`<a href="editpage?name=` ~ name ~ `">[Edit This Page]</a><br><br>` ~ "\n\n" ~ f);
	return mdfile.filterMarkdown(_mdflags).toHtml();
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
		// Note: This does a check for the existence of the directory
		// Only creates it if it doesn't exist
		mkdirRecurse(std.path.dirName(name));			
		if (!exists(name ~ ".md")) {
			executeShell(_editor ~ " " ~ name ~ ".md");
		}
		return renderPage(name);
	}
	
	export Element editpage(string name) {
		executeShell(_editor ~ " " ~ name ~ ".md");
		cgi.setResponseLocation("viewpage?name=" ~ name);
		return renderPage(name);
	}
	
	export Element index() {
		return viewpage("index");
	}
}
mixin FancyMain!Test;
