import path from "path";
import resolve from "@rollup/plugin-node-resolve";
import replace from "@rollup/plugin-replace";
import commonjs from "@rollup/plugin-commonjs";
import copy from "rollup-plugin-copy";
import url from "@rollup/plugin-url";
import svelte from "rollup-plugin-svelte";
import babel from "@rollup/plugin-babel";
import { terser } from "rollup-plugin-terser";
import config from "sapper/config/rollup.js";
import pkg from "./package.json";
import { string } from "rollup-plugin-string";
import { mdsvex } from "mdsvex";
import globImport from "./rollup.glob.js";
import remarkMath from "remark-math";
import rehypeKatexSvelte from "rehype-katex-svelte";
import dsv from "@rollup/plugin-dsv";

const mode = process.env.NODE_ENV;
const dev = mode === "development";
const legacy = !!process.env.SAPPER_LEGACY_BUILD;

const onwarn = (warning, onwarn) =>
  (warning.code === "MISSING_EXPORT" && /'preload'/.test(warning.message)) ||
  (warning.code === "CIRCULAR_DEPENDENCY" &&
    /[/\\]@sapper[/\\]/.test(warning.message)) ||
  onwarn(warning);

const preprocess = mdsvex({
  extensions: [".svx", ".md"],
  remarkPlugins: [remarkMath],
  rehypePlugins: [rehypeKatexSvelte],
});

export default {
  client: {
    input: config.client.input(),
    output: config.client.output(),
    plugins: [
      replace({
        preventAssignment: true,
        "process.browser": true,
        "process.env.NODE_ENV": JSON.stringify(mode),
      }),
      // https://github.com/plotly/plotly.js/issues/3518
      replace({
        preventAssignment: true,
        "}()": "this.d3 = d3;\n}.apply(self);",
        delimiters: ["this.d3 = d3;\n", ";"],
      }),
      svelte({
        compilerOptions: { dev, hydratable: true },
        extensions: [".svelte", ".svx", ".md"],
        preprocess: preprocess,
      }),
      url({
        sourceDir: path.resolve(__dirname, "src/node_modules/images"),
        publicPath: "/client/",
      }),
      resolve({ browser: true, dedupe: ["svelte"], preferBuiltins: false }),
      string({ include: "**/*.txt" }),
      string({ include: "**/*.scm" }),
      string({ include: "**/*.pl" }),
      dsv(),
      copy({
        targets: [
          {
            src: ["node_modules/katex/dist/fonts/*"],
            dest: "__sapper__/build/client/fonts",
          },
          {
            src: ["node_modules/katex/dist/fonts/*"],
            dest: "__sapper__/dev/client/fonts",
          },
          {
            src: ["node_modules/katex/dist/fonts/*"],
            dest: "__sapper__/export/fonts",
          },
        ],
      }),
      commonjs(),

      legacy &&
        babel({
          extensions: [".js", ".mjs", ".html", ".svelte"],
          babelHelpers: "runtime",
          exclude: ["node_modules/@babel/**"],
          presets: [["@babel/preset-env", { targets: "> 0.25%, not dead" }]],
          plugins: [
            "@babel/plugin-syntax-dynamic-import",
            ["@babel/plugin-transform-runtime", { useESModules: true }],
          ],
        }),

      !dev && terser({ module: true }),
    ],

    preserveEntrySignatures: false,
    onwarn,
  },

  server: {
    input: config.server.input(),
    output: config.server.output(),
    plugins: [
      replace({
        preventAssignment: true,
        "process.browser": false,
        "process.env.NODE_ENV": JSON.stringify(mode),
      }),
      svelte({
        compilerOptions: { dev, generate: "ssr", hydratable: true },
        emitCss: false,
        extensions: [".svelte", ".svx", ".md"],
        preprocess: preprocess,
      }),
      url({
        sourceDir: path.resolve(__dirname, "src/node_modules/images"),
        publicPath: "/client/",
        emitFiles: false, // already emitted by client build
      }),
      resolve({ dedupe: ["svelte"] }),
      commonjs(),
      globImport(),
      string({ include: "**/*.txt" }),
      string({ include: "**/*.scm" }),
      string({ include: "**/*.pl" }),
      dsv(),
    ],
    external: Object.keys(pkg.dependencies).concat(
      require("module").builtinModules
    ),

    preserveEntrySignatures: "strict",
    onwarn,
  },

  serviceworker: {
    input: config.serviceworker.input(),
    output: config.serviceworker.output(),
    plugins: [
      resolve(),
      replace({
        preventAssignment: true,
        "process.browser": true,
        "process.env.NODE_ENV": JSON.stringify(mode),
      }),
      commonjs(),
      !dev && terser(),
    ],

    preserveEntrySignatures: false,
    onwarn,
  },
};
