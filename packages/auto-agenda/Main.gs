// TODO: find these ids programmatically from a name relative to the sheet
const TEMPLATE_ID = "1jB7yedTuIftNUIv4UO_Chw_vDwz62hOm_aG-s3Nygvc";
const OUTPUT_FOLDER_ID = "1Tf1Cq9drhwjyRV3ocePDi82L9eHz6K5p";

function onOpen() {
  let menuEntries = [
    {
      name: "Create Autofilled Template",
      functionName: "AutofillDocFromTemplate",
    },
  ];
  let ss = SpreadsheetApp.getActiveSpreadsheet();
  ss.addMenu("Create", menuEntries);
}

function AutofillDocFromTemplate() {
  let ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getActiveSheet();

  let values = sheet
    .getRange(1, 1, sheet.getLastRow(), sheet.getLastColumn())
    .getValues();

  let header = values[0].filter((cell) => cell != "");
  let entries = values.slice(1).map((row) => row.slice(0, header.length));
  Logger.log(header);
  Logger.log(entries);

  let folder = DriveApp.getFolderById(OUTPUT_FOLDER_ID);

  for (row of entries) {
    let date = row[0].toISOString().slice(0, 10);
    let toastmaster = row[1];
    let name = `agenda ${date} ${toastmaster}`;
    Logger.log(`creating document for ${name}`);
    let docId = DriveApp.getFileById(TEMPLATE_ID)
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

  ss.toast("Templates have been complied!");
}
