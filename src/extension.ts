import { exec } from "child_process";
import {
  Definition,
  ExtensionContext,
  Position,
  ProviderResult,
  TextDocument,
  languages,
  window,
  workspace,
} from "vscode";

interface DefinitionKey {
  document: TextDocument;
  position: Position;
}

const definitionCache: Record<string, ProviderResult<Definition>> = {};

export function activate(/*context: ExtensionContext*/) {
  console.log("Activating the Just an Idea extension...");

  const jaiExePath =
    workspace.getConfiguration("just-an-idea").get("jaiPath") ?? "jai";
}

export function deactivate() {}

languages.registerDefinitionProvider(
  { language: "jai", scheme: "file" },
  {
    provideDefinition: (document, position) => {
      //TODO: Caching
      const range = document.getWordRangeAtPosition(position);
      const identifier = document.getText(range);
      return definitionCache[identifier];
    },
  }
);
