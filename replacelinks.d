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

string replaceLinks2(string s) {
	string result = "";
	
	void recurse(long ii) {
		if (ii >= s.length) {
			return;
		}
		long ind = s.indexOf("[#", ii);
		if (ind == -1) {
			result ~= s[ii..$];
			return;
		}
		long ind2 = s.indexOf("]", ind);
		enforce(ind2 > -1, "Unclosed link. Did you attempt to put a code block inside a link?\n\n" ~ s[ind..$]);
		result ~= s[ii..ind];
		string linktext = s[ind+2..ind2];
		long sep = linktext.indexOf("|");
		if (sep == -1) {
			result ~= `<a href="viewpage?name=` ~ linktext.strip ~ `">` ~ linktext.strip ~ `</a>`;
			return recurse(ind2+1);
		} else {
			result ~= `<a href="viewpage?name=` ~ linktext[0..sep].strip ~ `">` ~ linktext[sep+1..$].strip ~ `</a>`;
			return recurse(ind2+1);
		}
	}
	recurse(0);
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

string replaceLinks(string s) {
	return s
		.replaceAll(regex(`(\[#)(.*?)(\])(?!\()`), `<a href="viewpage?name=$2">$2</a>`)
		.replaceAll(regex(`(\[#)(.*?)(\|)(.*?)(\])(?!\()`), `<a href="viewpage4?name=$2">$4</a>`)
		.replaceAll(regex(`(^|\s)(#)(.*?)(\s|$)`, "m"), `$1<a href="tag?tagname=$3">#$3</a>`);
}
