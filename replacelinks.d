module minwiki.replacelinks;

import std.conv, std.exception, std.regex, std.stdio, std.string;

string findDelimiter(string s, long ind) {
	string result;
	
	void recurse(long ii) {
		if (ii >= s.length) {
			return;
		} else {
			if (s[ii] == '`') {
				result ~= "`";
				return recurse(ii+1);
			} else {
				return;
			}
		}
	}
	recurse(ind);
	return result;
}

string changeLinks(string s) {
	string result;
	
	void recurse(long ii) {
		if (ii >= s.length) {
			return;
		}
		long ind = s.indexOf("`", ii);
		if (ind == -1) {
			result ~= s[ii..$].replace("  \n", `<br>`).replaceLinks();
			return;
		} else {
			result ~= s[ii..ind].replace("  \n", `<br>`).replaceLinks();
			string delimiter = findDelimiter(s, ind);
			long ind2 = s.indexOf(delimiter, ind+delimiter.length);
			enforce(ind2 > 0, "Unclosed code block: " ~ s[ind..$]);
			result ~= s[ind..ind2+delimiter.length];
			return recurse(ind2+delimiter.length);
		}
	}
	recurse(0);
	return result;
}

string convertLink(Captures!(string) m) {
	string s = m.hit;
	auto ind = s.indexOf("|");
	if (ind < 0) {
		return `<a href="viewpage?name=` ~ s[2..$-1].strip ~ `">` ~ s[2..$-1].strip ~ "</a>";
	}
	else {
		string[] pieces = s.split("|");
		return `<a href="viewpage?name=` ~ pieces[0][2..$-1].strip ~ `">` ~ pieces[1][0..$-1].strip ~ "</a>";
	}
}

string replaceLinks(string s) {
	return replaceAll!(convertLink)(s, regex(`\[#[a-zA-Z].*?\](?!\()`))
		.replaceAll(regex(`(?<=^|<br>|\s)(#)([a-zA-Z][a-zA-Z0-9]*?)(?=<br>|\s|$)`, "m"), `<a href="tag?tagname=$2">#$2</a>`)
		.replaceAll(regex(`(?<=^|<br>|\s)(\[ \] )`, "m"), `&#9744; `)
		.replaceAll(regex(`(?<=^|<br>|\s)(\[x\] )`, "m"), `&#9745; `);
}
