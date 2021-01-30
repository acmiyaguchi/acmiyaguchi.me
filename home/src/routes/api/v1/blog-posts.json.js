import posts from "../../blog/_posts/*";
import path from "path";
import url from "url";
import querystring from "querystring";
import { sortBy } from "lodash";

export function get(req, res, next) {
  let parsed = url.parse(req.url);
  let query = querystring.parse(parsed.query);
  let results = sortBy(
    posts.map((p) => {
      let metadata = p.exports.metadata;
      // inject the path name into the metadata
      metadata.name = path.basename(p.path).split(".svx")[0];
      return metadata;
    }),
    ["date"]
  ).reverse();
  res.end(
    JSON.stringify(query.limit ? results.slice(0, query.limit) : results)
  );
}
