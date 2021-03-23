import ballerina/io;
import ballerina/regex;

public function main() returns error? {
    string resourceFile = "resources/r1.txt";
    stream<string, io:Error> corpusStream = check io:fileReadLinesAsStream(resourceFile);
    map<int> languageModel = {};
    error? e = corpusStream.forEach(function(string line) {
                                        if line.trim() != "" {
                                            string[] tokens = regex:split(line, "\\s+");
                                            string[] preprocessedTokens = tokens.map(preprocessText);
                                            foreach string token in preprocessedTokens {
                                                if languageModel.hasKey(token) {
                                                    languageModel[token] = <int>languageModel[token] + 1;
                                                } else {
                                                    languageModel[token] = 1;
                                                }
                                            }
                                        }
                                    });
    io:println(languageModel);
}

function preprocessText(string token) returns string {
    return regex:replaceAll(token.toLowerAscii(), "[^a-zA-Z]+", "");
}

function printStream(stream<anydata> strm) {
    error? e = strm.forEach(function(anydata val) {
                                io:println(val);
                            });
}
