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

  let serverOptions: ServerOptions = {
    run: {
      command: serverProcess,
      options: {
        cwd: context.extensionPath,
      },
      transport: TransportKind.stdio,
    },
    debug: {
      command: serverProcess,
      options: {
        cwd: context.extensionPath,
      },
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
