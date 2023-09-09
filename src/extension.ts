import { SpawnSyncReturns, exec, execFileSync } from "child_process";
import { readFile, opendir, open, close } from "fs";
import {
  Definition,
  ExtensionContext,
  Location,
  Position,
  Range,
  Uri,
  languages,
  window,
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

let jaiExePath: string;
let extensionPath: string;
let definitionCache: Record<string, Definition> = {};

const formatFileName = (name: string) =>
  name.replace(/\\/g, "/").replace(/^[a-z]:\//, (x) => x.toUpperCase());

const getDirPath = (name: string) => name.match(/^(.*)[\/\\].*/)?.[1];

const getModulePath = (name: string) => `${getDirPath(name)}/module.jai`;

const getModuleName = (name: string) => name.match(/[\/\\]?([^\/\\]+)[\/\\]module\.jai$/)?.[1] ?? "";

const parseDefinitions = () => {
  readFile(`${extensionPath}defs.out`, (err, data) => {
    if (err) {
      console.log(err.message);
    } else {
      const foundDefinitions: FoundDefinition[] = JSON.parse(data.toString());
      for (const foundDefinition of foundDefinitions) {
        definitionCache[foundDefinition.key] = new Location(
          Uri.file(foundDefinition.path),
          new Range(
            new Position(
              foundDefinition.start.line - 1,
              foundDefinition.start.column - 1
            ),
            new Position(
              foundDefinition.end.line - 1,
              foundDefinition.end.column - 1
            )
          )
        );
      }
    }
  });
};

const runCompiler = (file: string, type: "module" | "file") => {
  try {
    execFileSync(
      jaiExePath,
      [file, type, "--", "import_dir", `${extensionPath}/src/`, "meta", "extension"],
      { maxBuffer: undefined }
    );
    
    parseDefinitions();
  } catch (e) {
    console.log(e);
  }
};

const loadMore = () => {
  const currentFile = formatFileName(
    window.activeTextEditor?.document.fileName ?? ""
  );

  if (currentFile?.endsWith(".jai")) {
    const moduleFile = getModulePath(currentFile);
    open(moduleFile, (err, fd) => {
      if (err) {
        runCompiler(currentFile, "file");
      } else {
        close(fd);
        runCompiler(getModuleName(moduleFile), "module");
      }
    });
  }
};

export function activate(context: ExtensionContext) {
  jaiExePath = formatFileName(
    workspace.getConfiguration("just-an-idea").get("jaiPath") ?? "jai"
  );

  extensionPath = formatFileName(context.extensionPath);
  
  parseDefinitions();
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
      const file = formatFileName(document.fileName);
      const key = `${file}:${range.start.line + 1}:${
        range.start.character + 1
      }`;
      const definition = definitionCache[key];
      if (!definition) {
        loadMore();
      }
      return definition;
    },
  }
);
