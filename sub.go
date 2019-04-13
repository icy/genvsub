// Purpose : Simple alterntive to subenvst
// Author  : Ky-Anh Huynh
// License : MIT
// Features:
//  - Only process variable name encapsulated by ${}, e.g, ${foo}.
//  - Option `-set-u` to raise error when some variable is unset.

package main

import "fmt"
import "regexp"
import "os"
import "io"
import "bufio"
import "flag"

var re = regexp.MustCompile(`\${[^}]+}`)
var all_var_is_set = true
var last_process_var = ""

// Replace ${VAR_NAME} with its environment value
func repl(in []byte) []byte {
	in_st := string(in)
	var_name := in_st[2 : len(in_st)-1]
	var_val, var_set := os.LookupEnv(var_name)
	all_var_is_set = all_var_is_set && var_set
	last_process_var = var_name
	return []byte(var_val)
}

// https://github.com/jprichardson/readline-go/blob/master/readline.go
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
	output := re.ReplaceAllFunc([]byte(input), repl)
	return output
}

func scanLine(input string) [][]byte {
	output := re.FindAll([]byte(input), -1)
	return output
}

func main() {
	var setMinusU bool
	var scanOnly bool

	flag.BoolVar(&setMinusU, "set-u", false, "Raise error when some variable is not set.")
	flag.BoolVar(&scanOnly, "variables", false, "Output ocurrences of variables in input.")
	flag.BoolVar(&scanOnly, "v", false, "Output ocurrences of variables in input.")

	flag.CommandLine.Parse(os.Args[1:])

	eachLine(os.Stdin, func(line string) {
		if scanOnly {
			if found := scanLine(line); found != nil {
				for _, v := range found {
					fmt.Printf("%s\n", v[2:len(v)-1])
				}
			}
		} else {
			fmt.Printf("%s", replLine(line))
			if setMinusU && !all_var_is_set {
				fmt.Fprintf(os.Stderr, ":: Environment variable '%s' is not set.\n", last_process_var)
				os.Exit(1)
			}
		}
	})
}
