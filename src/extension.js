"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const child_process_1 = require("child_process");
const fs_1 = require("fs");
const vscode_1 = require("vscode");
let definitionCache = {};
const formatFileName = (name) => name.replace(/\\/g, "/").replace(/^[a-z]:\//, (x) => x.toUpperCase());
function activate(context) {
    console.log("Hello!");
    const jaiExePath = formatFileName(vscode_1.workspace.getConfiguration("just-an-idea").get("jaiPath") ?? "jai");
    // TODO: Find module in current folder
    // const currentFile = formatFileName(
    //   window.activeTextEditor?.document.fileName ?? ""
    // );
    const currentFile = "main.jai";
    const extensionPath = formatFileName(context.extensionPath);
    if (currentFile?.endsWith(".jai")) {
        (0, child_process_1.exec)(`"${jaiExePath}" "${currentFile}" -- import_dir "${extensionPath}/src/" meta extension`, { maxBuffer: undefined }, (error, stdout, stderr) => {
            if (error) {
                console.log(`Error when running the jai compiler (exit code ${error.code}): ${error.message}`);
                console.log(`[Standard Out]: ${stdout}`);
                console.log(`[Standard Error]: ${stderr}`);
            }
            else {
                (0, fs_1.readFile)("defs.out", (err, data) => {
                    if (!err) {
                        const foundDefinitions = JSON.parse(data.toString());
                        definitionCache = {};
                        foundDefinitions.forEach((def) => (definitionCache[def.key] = new vscode_1.Location(vscode_1.Uri.file(def.path), new vscode_1.Range(new vscode_1.Position(def.start.line - 1, def.start.column - 1), new vscode_1.Position(def.end.line - 1, def.end.column - 1)))));
                    }
                });
            }
        });
    }
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;
vscode_1.languages.registerDefinitionProvider({ language: "jai", scheme: "file" }, {
    provideDefinition: (document, position) => {
        const range = document.getWordRangeAtPosition(position);
        if (!range) {
            return null;
        }
        const identifier = document.getText(range);
        const file = formatFileName(document.fileName);
        const key = `${file}:${range.start.line + 1}:${range.start.character + 1}`;
        return definitionCache[key];
    },
});
//# sourceMappingURL=extension.js.map