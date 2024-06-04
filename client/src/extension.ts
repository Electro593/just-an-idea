import * as path from 'path';
import {workspace, ExtensionContext} from 'vscode';

import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  const serverProcess = context.asAbsolutePath(
    path.join('out', 'server.exe')
  );
  
  let serverOptions: ServerOptions = {
    run: {
      command: serverProcess,
      transport: TransportKind.stdio
    },
    debug: {
      command: serverProcess,
      transport: TransportKind.stdio
    }
  };
  
  let clientOptions: LanguageClientOptions = {
    documentSelector: [
      {
        scheme: 'file',
        language: 'jai'
      }
    ],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.jai')
    }
  };
  
  client = new LanguageClient(
    'jaiLanguageServer',
    'Jai Language Server',
    serverOptions,
    clientOptions
  );
  
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}