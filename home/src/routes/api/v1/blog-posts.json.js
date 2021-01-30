import posts from "../../blog/_posts/*";
import path from "path";
import { sortBy } from "lodash";

export function get(req, res, next) {
  res.end(
    JSON.stringify(
      sortBy(
        posts.map((p) => {
          let metadata = p.exports.metadata;
          // inject the path name into the metadata
          metadata.name = path.basename(p.path).split(".svx")[0];
          return metadata;
        }),
        ["date"]
      ).reverse()
    )
  );
}
