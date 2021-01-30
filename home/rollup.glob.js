import path from "path";
import glob from "glob";

// named glob imports as a modified version of
// https://github.com/kei-ito/rollup-plugin-glob-import

function generateCode(files) {
  return (
    files
      .map((file, i) => `import * as _${i} from ${JSON.stringify(file)};`)
      .join("\n") +
    `export default [${[...Array(files.length).keys()]
      .map((i) => `{"path": "${files[i]}", "exports": _${i}}`)
      .join(", ")}];`
  );
}

export default function globImport() {
  const generatedCodes = new Map();
  return {
    name: "glob-import",
    async resolveId(importee, importer) {
      const importerDirectory = path.dirname(importer);
      let files = glob.sync(importee, { cwd: importerDirectory });
      const code = generateCode(files);
      const tempPath = path.join(
        importerDirectory,
        importee.replace(/\W/g, (c) => `_${c.codePointAt(0)}_`)
      );
      generatedCodes.set(tempPath, code);
      return tempPath;
    },
    // TODO: regenerate the server bundle if one of the globs changes
    load(id) {
      return generatedCodes.get(id);
    },
  };
}
