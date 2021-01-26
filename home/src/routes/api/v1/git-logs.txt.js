import child_process from "child_process";

export function get(req, res, next) {
  let logs = child_process.execSync(
    `git log -n 10 --pretty="format:%hn %cd %s" --date=rfc`
  );
  res.end(logs);
}
