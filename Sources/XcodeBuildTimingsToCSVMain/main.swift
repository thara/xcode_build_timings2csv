import Foundation.NSFileHandle
import Commander
import Rainbow

import XcodeBuildTimingsToCSV

struct StandardErrorOutputStream: TextOutputStream {
    let stderr = FileHandle.standardError

    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return // encoding failure
        }
        stderr.write(data)
    }
}

let recordFields = Record.fields.joined(separator: ",")

func readRecordLines(_ filename: String) -> ArraySlice<String>? {
    guard let text = try? String(contentsOfFile: filename, encoding: String.Encoding.utf8) else {
        return nil
    }

    var lines: [String] = []
    text.enumerateLines { line, _ in 
        lines.append(line)
    }

    // remove headers & summary
    return lines.suffix(from: 2).prefix(while: { !$0.hasPrefix(" ") } )
}

func dumpRecords(_ recordLines: ArraySlice<String>, comparator: (Record, Record) -> Bool) {
    recordLines.map { RecordParser.parse(input: $0) }.compactMap { $0 }.sorted(by: comparator).forEach { r in print("\(r)") }
}

Group {
    $0.command("dump",
        Argument<String>("filename"),
        Option("key", default: "No", description: "Record field as sort key"),
        Flag("reverse", description: "Reverse sort in order"),
        description: "Dump record lines"
    ) { (filename, field, reverse) in

        guard Record.fields.contains(field) else {
            var errStream = StandardErrorOutputStream()
            print("Invalid field name : '\(field)'".red, to: &errStream)
            print("Choose one field from {\(recordFields)}".red, to: &errStream)
            exit(EXIT_FAILURE)
        }

        guard let recordLines = readRecordLines(filename) else {
            var errStream = StandardErrorOutputStream()
            print("Can not open \(filename).".red, to: &errStream)
            exit(EXIT_FAILURE)
        }

        print(recordFields)

        let cmp = Record.compared(by: field)
        dumpRecords(recordLines, comparator: reverse ? { !cmp($0, $1) } : cmp)
    }

    $0.command("rank",
        Argument<String>("filename"),
        Option("key", default: "User", description: "Record field as rankinig key"),
        Flag("reverse", description: "Reverse ranking order"),
        description: "Dump record lines as ranking"
    ) { (filename, field, reverse) in

        guard Record.fields.contains(field) else {
            var errStream = StandardErrorOutputStream()
            print("Invalid field name : '\(field)'".red, to: &errStream)
            print("Choose one field from {\(recordFields)}".red, to: &errStream)
            exit(EXIT_FAILURE)
        }

        guard let recordLines = readRecordLines(filename) else {
            var errStream = StandardErrorOutputStream()
            print("Can not open \(filename).".red, to: &errStream)
            exit(EXIT_FAILURE)
        }

        print(recordFields)

        let cmp = Record.compared(by: field)
        dumpRecords(recordLines, comparator: reverse ? cmp : { !cmp($0, $1) })
    }
}.run()
