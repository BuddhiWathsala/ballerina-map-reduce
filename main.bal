import ballerina/io;
import ballerina/regex;

class LanguageModel {
    map<int> frequencies = {};
    function addElement(string token) {
        lock {
            if self.frequencies.hasKey(token) {
                self.frequencies[token] = <int>self.frequencies[token] + 1;
            } else {
                self.frequencies[token] = 1;
            }
        }
    }

    function getFrequencies() returns map<int> {
        return self.frequencies;
    }
}

LanguageModel languageModel = new;

public function main() returns error? {
    string[] resourceFiles = ["resources/r1.txt", "resources/r2.txt", "resources/r3.txt"];
    future<error?> f1 = @strand {thread: "any"} start processFile(resourceFiles[0]);
    future<error?> f2 = @strand {thread: "any"} start processFile(resourceFiles[1]);
    future<error?> f3 = @strand {thread: "any"} start processFile(resourceFiles[2]);
    map<error?> results = wait {f1, f2, f3};
    io:println(languageModel.getFrequencies());

}

function processFile(string fileName) returns error? {
    stream<string, io:Error> corpusStream = check io:fileReadLinesAsStream(fileName);
    error? e = corpusStream.forEach(function(string line) {
                                        if line.trim() != "" {
                                            string[] tokens = regex:split(line, "\\s+");
                                            string[] preprocessedTokens = tokens.map(preprocessText);
                                            foreach string token in preprocessedTokens {
                                                languageModel.addElement(token);
                                            }
                                        }
                                    });
}

function processEntireFile(string fileName) returns error? {
    stream<string, io:Error> corpusStream = check io:fileReadLinesAsStream(fileName);
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
