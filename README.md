# minwiki2

- Internal wiki links are `[#page]` or `[#page | Page Description]`.
- Tags are `#tag`.
- `[ ]` is replaced with a symbol to denote an incomplete task.
- `[x]` is replaced with a symbol to denote a completed task.
- Replacement is only done outside of code blocks.
- If you're running the server on port 8088, you can use this bookmarklet to add pages automatically to the links.md file:

```
javascript:(function(){window.open('http://127.0.0.1:8088/bookmark?url='+encodeURIComponent(document.location)+'&desc='+encodeURIComponent(document.title));}())
```

You can adjust the port as appropriate.
