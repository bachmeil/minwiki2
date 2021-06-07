module minwiki.tem;

import arsd.web;

class Wikisite: ApiProvider {
	override Element _getGenericContainer()
		out(ret) {
			assert(ret !is null);
		}
		body {
			auto document = new TemplatedDocument(
"<!DOCTYPE html>
<html>
<head>
	<title>minwiki</title>"

/* You can put CSS here
 * Default is a lightweight plain CSS theme
 * I've also included the oddmuse wiki theme. To use it, comment the
 * line with plaincss and uncomment the oddmuse line.
 * To show the use of a CDN, you can use the Yeti Bootswatch theme.
 * If you want to use an external CSS file, you should have it on a
 * webserver, otherwise you force all users to have the same CSS file
 * in the same location on their machine, which is a mess - and good luck
 * if you decide to make a change in the CSS.
 */
~ plaincss
// ~ oddmuse 
// ~ bootstrapYeti

/* Uncomment this for Mathjax support. By default, inline equations are
 * single quoted: '$...$'. You can change that in the mathjax definition
 * above.
 */
~ mathjax

~ "</head>
<body>
	<div id=\"body\"></div>
	<a href=\"index\">[Index]</a>
</body>
</html>");
		if(this.reflection !is null)
			document.title = this.reflection.name;
		auto container = document.requireElementById("body");
		return container;
	}
}

enum bootstrapYeti = `<link href="https://maxcdn.bootstrapcdn.com/bootswatch/4.0.0-beta.3/yeti/bootstrap.min.css" rel="stylesheet" integrity="sha384-xpQNcoacYF/4TKVs2uD3sXyaQYs49wxwEmeFNkOUgun6SLWdEbaCOv8hGaB9jLxt" crossorigin="anonymous"></link>`;

enum plaincss = `<style>
body {
    margin: auto;
    max-width: 800px;
    font-size: 120%;
    margin-top: 20px;
}

a {
    text-decoration: none;
}

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

h1, h2, h3 {
	font-family: sans;
	font-size: 140%;
}
</style>`;

enum oddmuse = `
<style>
body {
    background: #fff;
    padding: 2% 5%;
    margin: 0;
    font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif;
    font-size: 15pt;
}

div.header h1 {
    margin-top: 2ex;
}

a {
    text-decoration: none;
    color: #a00;
}

a:visited {
    color: #d88;
}

div.header h1 a:hover, h1 a:hover, h2 a:hover, h3 a:hover, h4 a:hover,
a:hover, span.caption a.image:hover {
     background: #fee;
}

img.logo {
    float: right;
    clear: right;
    border-style: none;
    background-color: #fff;
}

img {
    padding: 0.5em;
    margin: 0 1em;
    max-width: 95%;
}

a.image:hover {
    background: inherit;
}

a.image:hover img {
    background: #fee;
}

/* a.definition soll aussehen wie h2 */
h2, p > a.definition {
    display: block;
    clear: both;
}

/* Such Link im h1 soll nicht auffallen. */
h1, h2, h3, h4, h1 a, h1 a:visited, p > a.definition {
    color: #666;
    font-size: 30pt;
    font-weight: normal;
    margin: 4ex 0 1ex 0;
    padding: 0;
    border-bottom: 1px solid #000;
}

h3, h4 {
    font-size: inherit;
}

div.diff {
    padding: 1em 3em;
}
div.old {
    background-color: #FFFFAF;
}
div.new {
    background-color: #CFFFCF;
}
div.old p, div.new p {
    padding: 0.5em 0;
}
div.refer { padding-left: 5%; padding-right: 5%; font-size: smaller; }
div[class="content refer"] p { margin-top: 2em; }
div.content div.refer hr { display: none; }
div.content div.refer { padding: 0; font-size: medium; }
div.content div.refer p { margin: 0; }
div.refer a { display: block; }
table.history { border-style: none; }
td.history { border-style: none; }

table.user {
    border-style: none;
    margin-left: 3em;
}
table.user tr td {
    border-style: none;
    padding: 0.5ex 1ex;
}

dt {
    font-weight: bold;
}
dd {
    margin-bottom: 1ex;
}

textarea {
    width: 100%;
    height: 80%;
    font-size: 12pt;
}
textarea#summary { height: 3em; }
input {
    font-size: 12pt;
}
div.image span.caption {
    margin: 0 1em;
}
li img, img.smiley, .noborder img {
    border: none;
    padding: 0;
    margin: 0;
    background: #fff;
    color: #000;
}
/* Google +1 */
a#plus1 img {
    background-color: #fff;
    padding: 0;
    margin: 0;
    border: none;
}

div.header img, div.footer img { border: 0; padding: 0; margin: 0; }
/* No goto bar at the bottom. */
.footer .gotobar, .footer .edit br { display: none; }

.left { float: left; }
.right { float: right; }
div.left .left, div.right .right {
    float: none;
}
.center { text-align: center; }

span.author {
    color: #501;
}

span.bar a:first-child {
    margin-left: -0.5ex;
}

span.bar a {
    padding-right: 0.5ex;
    padding-left: 0.5ex;
}

.rc .author {
    color: #655;
}

.rc strong {
    font-weight: normal;
    color: inherit;
}

.rc li {
    position: relative;
    padding: 1ex 0;
}

hr {
    border: none;
    color: black;
    background-color: #000;
    height: 2px;
    margin-top: 2ex;
}

div.footer hr {
    height: 4px;
    margin: 2em 0 1ex 0;
    clear: both;
}

div.content > div.comment {
    border-top: none;
    padding-top: 0;
    border-left: 1ex solid #bbb;
    padding-left: 1ex;
}

div.wrapper > div.comment {
    border-top: 2px solid #000;
    padding-top: 2em;
}

pre {
    padding: 0.5em;
    margin-left: 1em;
    margin-right: 2em;
    white-space: pre;
    overflow: hidden;
    white-space: pre-wrap;      /* CSS 3 */
    white-space: -moz-pre-wrap; /* Mozilla, since 1999 */
    white-space: -pre-wrap;     /* Opera 4-6 */
    white-space: -o-pre-wrap;   /* Opera 7 */
    word-wrap: break-word;      /* Internet Explorer 5.5+ */
}

tt, pre, code {
    font-size: 80%;
}

code {
    background: #eee;
    white-space: pre-wrap;
}
</style>`;

enum mathjax = "<script type=\"text/x-mathjax-config\">
MathJax.Hub.Config({
  tex2jax: {inlineMath: [[\"'$\",\"$'\"]]}
});
</script>
<script type=\"text/javascript\" async
  src=\"https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.2/MathJax.js?config=TeX-MML-AM_CHTML\">
</script>";



