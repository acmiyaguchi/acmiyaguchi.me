import posts from "../../blog/_posts/*.svx";
import path from "path";
import { sortBy } from "lodash";

export function get(req, res, next) {
  let results = sortBy(
    posts.map((p) => {
      let metadata = p.exports.metadata;
      // inject the path name into the metadata
      metadata.name = path.basename(p.path).split(".svx")[0];
      return metadata;
    }),
    ["date"]
  ).reverse();
  res.end(JSON.stringify(results));
}
