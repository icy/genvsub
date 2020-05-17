/*
Purpose : Simple alterntive to subenvst
Author  : Ky-Anh Huynh
License : MIT
Features:

  - [x] Only process variable name encapsulated by ${}, e.g, ${foo}.
  - [x] Option `-u` to raise error when some variable is unset.
*/

package main

import "fmt"
import "regexp"
import "os"
import "io"
import "bufio"
import "flag"

/* internal global controllers */
var regVarname = regexp.MustCompile(`\${[^}]+}`)
var allVarSet = true
var lastProcessedVar = ""

/* users' controllers */
var setMinusU bool
var scanOnly bool
var varPrefix = ""

// Internal function that replaces ${VAR_NAME} with environment value.
func repl_func(in []byte) []byte {
	in_st := string(in)
	var_name := in_st[2 : len(in_st)-1]
	var_val, var_set := os.LookupEnv(var_name)
	allVarSet = allVarSet && var_set
	lastProcessedVar = var_name
	return []byte(var_val)
}

// https://github.com/jprichardson/readline-go/blob/master/readline.go
// Invoke function `f` on each each line from the reader.
func eachLine(reader io.Reader, f func(string)) {
	buf := bufio.NewReader(reader)
	line, err := buf.ReadBytes('\n')
	for err == nil {
		f(string(line))
		line, err = buf.ReadBytes('\n')
	}
	f(string(line))
}

func replLine(input string) []byte {
	output := regVarname.ReplaceAllFunc([]byte(input), repl_func)
	return output
}

/*
  Scan the line and find all variable names match our regular expression.
  Only used when `scanOnly` option is instructed.
*/
func scanLine(input string) [][]byte {
	output := regVarname.FindAll([]byte(input), -1)
	return output
}

func doLine(line string) {
	if scanOnly {
		if found := scanLine(line); found != nil {
			for _, v := range found {
				fmt.Printf("%s\n", v[2:len(v)-1])
			}
		}
	} else {
		fmt.Printf("%s", replLine(line))
		if setMinusU && !allVarSet {
			fmt.Fprintf(os.Stderr, ":: Environment variable '%s' is not set.\n", lastProcessedVar)
			os.Exit(1)
		}
	}
}

func main() {
	flag.BoolVar(&setMinusU, "u", false, "Raise error when some variable is not set.")
	flag.BoolVar(&scanOnly, "v", false, "Output ocurrences of variables in input.")
	flag.StringVar(&varPrefix, "p", "", "Limit substitution to variables that match this prefix.")
	flag.CommandLine.Parse(os.Args[1:])
	regVarname = regexp.MustCompile(fmt.Sprintf("\\${%s[^}]+}", varPrefix))
	fmt.Fprintf(os.Stderr, ":: genvsub is reading from STDIN and looking for variables with regexp '%s'\n", regVarname)
	eachLine(os.Stdin, doLine)
}
