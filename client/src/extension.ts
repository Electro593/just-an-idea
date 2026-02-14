import * as path from "path";
import { workspace, ExtensionContext } from "vscode";

import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  const serverName = process.platform == "win32" ? "server.exe" : "server";

  const serverProcess = context.asAbsolutePath(path.join("out", serverName));

  const config = workspace.getConfiguration("justAnIdea");
  const jaiPath = config.get<string>("jaiPath") ?? "jai";
  const buildFile = config.get<string>("buildFile");
  const buildArgs = config.get<unknown[]>("buildArgs") ?? [];

  if (!buildFile) throw new Error("justAnIdea.buildFile cannot be empty");
  for (const [i, arg] of buildArgs.entries())
    if (typeof arg != "string")
      throw new Error(
        `justAnIdea.buildArgs[${i}] must be a string. Got: ${arg}`,
      );

  const resolvedBuildFile = path.resolve(buildFile!);

  const args = [jaiPath, resolvedBuildFile, ...(buildArgs as string[])];

  let serverOptions: ServerOptions = {
    run: {
      command: serverProcess,
      options: { cwd: context.extensionPath },
      args,
      transport: TransportKind.stdio,
    },
    debug: {
      command: serverProcess,
      options: { cwd: context.extensionPath },
      args,
      transport: TransportKind.stdio,
    },
  };

  let clientOptions: LanguageClientOptions = {
    documentSelector: [
      {
        scheme: "file",
        language: "jai",
      },
    ],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher("**/*.jai"),
    },
  };

  client = new LanguageClient(
    "jaiLanguageServer",
    "Jai Language Server",
    serverOptions,
    clientOptions,
  );

  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
