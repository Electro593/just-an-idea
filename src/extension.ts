import { exec } from "child_process";
import { readFile } from "fs";
import {
  Definition,
  ExtensionContext,
  Location,
  Position,
  Range,
  Uri,
  languages,
  workspace,
} from "vscode";

interface FoundDefinition {
  key: string;
  path: string;
  start: {
    line: number;
    column: number;
  };
  end: {
    line: number;
    column: number;
  };
}

let definitionCache: Record<string, Definition> = {};

const formatFileName = (name: string) =>
  name.replace(/\\/g, "/").replace(/^[a-z]:\//, (x) => x.toUpperCase());

export function activate(context: ExtensionContext) {
  const jaiExePath = formatFileName(
    workspace.getConfiguration("just-an-idea").get("jaiPath") ?? "jai"
  );

  // TODO: Find module in current folder
  // const currentFile = formatFileName(
  //   window.activeTextEditor?.document.fileName ?? ""
  // );
  const currentFile = "main.jai";

  const extensionPath: string = formatFileName(context.extensionPath);

  if (currentFile?.endsWith(".jai")) {
    exec(
      `"${jaiExePath}" "${currentFile}" -- import_dir "${extensionPath}/src/" meta extension`,
      { maxBuffer: undefined },
      (error, stdout, stderr) => {
        if (error) {
          console.log(
            `Error when running the jai compiler (exit code ${error.code}): ${error.message}`
          );
          console.log(`[Standard Out]: ${stdout}`);
          console.log(`[Standard Error]: ${stderr}`);
        } else {
          readFile("defs.out", (err, data) => {
            if (!err) {
              const foundDefinitions: FoundDefinition[] = JSON.parse(
                data.toString()
              );
              definitionCache = {};
              foundDefinitions.forEach(
                (def) =>
                  (definitionCache[def.key] = new Location(
                    Uri.file(def.path),
                    new Range(
                      new Position(def.start.line - 1, def.start.column - 1),
                      new Position(def.end.line - 1, def.end.column - 1)
                    )
                  ))
              );
            }
          });
        }
      }
    );
  }
}

export function deactivate() {}

languages.registerDefinitionProvider(
  { language: "jai", scheme: "file" },
  {
    provideDefinition: (document, position) => {
      const range = document.getWordRangeAtPosition(position);
      if (!range) {
        return null;
      }
      const identifier = document.getText(range);
      const file = formatFileName(document.fileName);
      const key = `${file}:${range.start.line + 1}:${
        range.start.character + 1
      }`;
      return definitionCache[key];
    },
  }
);
