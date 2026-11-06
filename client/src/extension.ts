import * as path from "path";
import * as vscode from "vscode";
import fs from "fs/promises";
import which from "which";

import {
  Executable,
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";
import { spawn } from "child_process";

let client: LanguageClient;

function getServerOptions(options: {
  context: vscode.ExtensionContext;
  command: string;
  args: string[];
  spawnRaw?: boolean;
  trace?: boolean;
}): ServerOptions {
  const { context, command, args, spawnRaw = true, trace = false } = options;

  if (!spawnRaw) {
    const executable: Executable = {
      command,
      args,
      transport: TransportKind.stdio,
      options: {
        cwd: context.extensionPath,
        env: process.env,
        detached: false,
        shell: false,
      },
    };

    return { run: executable, debug: executable };
  }

  return () => {
    const serverProcess = spawn(command, args, {
      cwd: context.extensionPath,
      env: process.env,
      shell: false,
      detached: false,
    });

    if (trace) {
      const originalWrite = serverProcess.stdin.write.bind(serverProcess.stdin);
      serverProcess.stdin.write = (
        chunk: any,
        encoding?: any,
        cb?: any,
      ): boolean => {
        console.log(`[RAW SERVER STDIN]: ${chunk.toString("utf8")}`);
        return originalWrite(chunk, encoding, cb);
      };

      serverProcess.stdout.on("data", (chunk: Buffer) => {
        console.log(`[RAW SERVER STDOUT]: ${chunk.toString("utf8")}`);
      });

      serverProcess.stderr.on("data", (chunk: Buffer) => {
        console.log(`[RAW SERVER STDERR]: ${chunk.toString("utf8")}`);
      });
    }

    return Promise.resolve({
      writer: serverProcess.stdin,
      reader: serverProcess.stdout,
    });
  };
}

export async function activate(context: vscode.ExtensionContext) {
  const config = vscode.workspace.getConfiguration("justAnIdea");
  const jaiPath = config.get<string>("jaiPath") ?? "jai";
  const buildFile = config.get<string>("buildFile");
  const buildArgs = config.get<unknown[]>("buildArgs") ?? [];

  if (!buildFile) throw new Error("justAnIdea.buildFile cannot be empty");
  for (const [i, arg] of buildArgs.entries()) {
    if (typeof arg !== "string")
      throw new Error(
        `justAnIdea.buildArgs[${i}] must be a string. Got: ${arg}`,
      );

    if (arg === "--")
      throw new Error(
        `justAnIdea.buildArgs[${i}] cannot have the value "--", since this is reserved for the language server metaprogram"`,
      );
  }

  try {
    await fs.rm(context.asAbsolutePath("log"), {
      recursive: true,
      force: true,
    });
  } catch (err) {
    console.error("Failed to delete log files:", err);
  }

  let command = jaiPath;
  try {
    command = await which(command);
  } catch {
    command = path.resolve(command);
  }

  const args = [
    path.resolve(buildFile!),
    ...(buildArgs as string[]),
    "--",
    "import_dir",
    "server/src/modules",
    "meta",
    "Server",
  ];

  const serverOptions = getServerOptions({
    context,
    command,
    args,
  });

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "jai" }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher("**/*.jai"),
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
