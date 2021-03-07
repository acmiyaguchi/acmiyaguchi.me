// variables share global scope, AMG = Agenda Minutes Generator
const AMG_AGENDA_TEMPLATE_ID = "1to1G9m12Om-0u5rDfxyPhwdShiaDVaa55R8SP_7XvMY";
const AMG_MINUTES_TEMPLATE_ID = "11NdRpVHwGTBLiCoCQmr8sDlskHnfkjzMMrhnB5iPpU8";
const AMG_OUTPUT_FOLDER_ID = "1Tf1Cq9drhwjyRV3ocePDi82L9eHz6K5p";

function onOpen() {
  let menuEntries = [
    {
      name: "Generate Minutes",
      functionName: "generateMinutes",
    },
  ];
  let ss = SpreadsheetApp.getActiveSpreadsheet();
  ss.addMenu("Create", menuEntries);
}

function normalizeName(name) {
  return name
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, " ")
    .trim()
    .split(/\s+/)
    .join("_");
}

// Convert spreadsheet data (csv) into an array of objects
function fetchSpreadsheetData(sheetName = "Roles") {
  let ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);

  let values = sheet
    .getRange(1, 1, sheet.getLastRow(), sheet.getLastColumn())
    .getValues();

  let header = values[0].filter((cell) => cell != "").map(normalizeName);
  let entries = values
    .slice(1)
    .map((row) =>
      // map each column to it's corresponding header and create an object
      Object.fromEntries(
        row.slice(0, header.length).map((col, i) => [header[i], col])
      )
    )
    // return in reverse chronological order
    .reverse();

  Logger.log(header, data);
  Logger.log(`number of entries: ${entries.length}`);
  return entries;
}

function generateMinutes() {
  let data = fetchSpreadsheetData("Roles");
  Logger.log(JSON.stringify(data[0], " ", 2));
}

function fillTemplate(
  output_folder_id,
  template_id,
  title_formatter = (row) => `${row.toISOString().slice(0, 10)}`
) {
  let folder = DriveApp.getFolderById(output_folder_id);

  for (row of entries) {
    let date = row[0].toISOString().slice(0, 10);
    let toastmaster = row[1];
    let name = `agenda ${date} ${toastmaster}`;
    Logger.log(`creating document for ${name}`);
    let docId = DriveApp.getFileById(template_id)
      .makeCopy(name, folder)
      .getId();
    let doc = DocumentApp.openById(docId);
    let body = doc.getActiveSection();

    for (let i = 0; i < header.length; i++) {
      let variable = header[i].toUpperCase().replace(" ", "_");
      body.replaceText(variable, row[i]);
    }

    doc.saveAndClose();
  }

  ss.toast("Templates have been compiled!");
}
