import ballerina/io;
import ballerina/regex;

# Thread safe language model.
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

# Global language model instantiation.
LanguageModel languageModel = new;

public function main() returns error? {
    string[] resourceFiles = ["resources/r1.txt", "resources/r2.txt", "resources/r3.txt"];
    future<error?> f1 = @strand {thread: "any"} start processFile(resourceFiles[0]);
    future<error?> f2 = @strand {thread: "any"} start processFile(resourceFiles[1]);
    future<error?> f3 = @strand {thread: "any"} start processFile(resourceFiles[2]);
    map<error?> results = wait {f1, f2, f3};
    io:println(languageModel.getFrequencies());

}

# Process a given file and update the thread safe global language model.
# + fileName - file name as a string
# + return - error or null
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

# Process a given file and create a new language model.
# + fileName - file name as a string
# + return - error or null
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

# Preprocess a given text.
# + token - token string to be processed
# + return - token after the processing
function preprocessText(string token) returns string {
    return regex:replaceAll(token.toLowerAscii(), "[^a-zA-Z]+", "");
}

# Print a stream
# + strm - stream
function printStream(stream<anydata> strm) {
    error? e = strm.forEach(function(anydata val) {
                                io:println(val);
                            });
}
