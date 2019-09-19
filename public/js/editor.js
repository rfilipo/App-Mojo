var editor = ace.edit("app-editor");

editor.setTheme("ace/theme/monokai");
editor.session.setMode("ace/mode/markdown");
editor.setOptions({
    autoScrollEditorIntoView: true,
    copyWithEmptySelection: true,
    minLines: 10
});
