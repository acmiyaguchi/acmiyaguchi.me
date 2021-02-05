// See: https://www.dannyblaker.com/fishinfordham/autofill-a-template-from-a-google-sheet-and-email-as-a-pdf-using-google-scripts
// this is the template file id. You can find this in the URL of the google
// document template. For example, if your URL Looks like this:
// https://docs.google.com/document/d/1SDTSW2JCItWMGkA8cDZGwZdAQa13sSpiYhiH-Kla6VA/edit,
// THEN the ID would be 1SDTSW2JCItWMKkA8cDZGwZdAQa13sSpiYhiH-Kla6VA
const TEMPLATE_ID = "1jB7yedTuIftNUIv4UO_Chw_vDwz62hOm_aG-s3Nygvc";
// Enter the name of the folder where you want to save your new documents. for
// example, this could be "Output Folder".
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
    .getRange(1, 1, sheet.getLastRow() - 1, sheet.getLastColumn())
    .getValues();
  let header = values[0].filter((cell) => cell != "");
  let entries = values.slice(1).filter((row) => row.slice(1, header.length));
  Logger.log(header, entries);

  let folder = DriveApp.getFolderById(OUTPUT_FOLDER_ID);
  let doc = DocumentApp.create(`Agenda for ${entries[0][0]}`);
  let file = DriveApp.getFileById(doc.getId());

  folder.addFile(file);

  let row = entries[0];
  let templateDocId = DriveApp.getFileById(TEMPLATE_ID).makeCopy().getId();
  let template = DocumentApp.openById(templateDocId);
  let body = template.getActiveSection();

  for (let i = 0; i < header.length; i++) {
    let variable = header[i].upper().replace(" ", "_");
    body.replaceText(`%${variable}%`, row[i]);
  }

  appendToDoc(template, doc);

  template.saveAndClose();
  doc.saveAndClose();

  ss.toast("Template has been complied!");
}

function appendToDoc(src, dst) {
  for (let i = 0; i < src.getNumChildren(); i++) {
    appendElementToDoc(dst, src.getChild(i));
  }
}

function appendElementToDoc(doc, object) {
  let type = object.getType();
  let element = object.removeFromParent();
  Logger.log("Element type is " + type);
  if (type == "PARAGRAPH") {
    doc.appendParagraph(element);
  } else if (type == "TABLE") {
    doc.appendTable(element);
  }
}
