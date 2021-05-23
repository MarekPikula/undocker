package cmdlxcconfig

import (
	"errors"
	"fmt"
	"io"
	"os"

	goflags "github.com/jessevdk/go-flags"
	"git.sr.ht/~motiejus/code/undocker/lxcconfig"
)

const _description = "Create an LXC-compatible container configuration"

// Command is an implementation of go-flags.Command
type Command struct {
	configer func(io.ReadSeeker, io.Writer) error
	Stdout   io.Writer

	PositionalArgs struct {
		Infile  goflags.Filename `long:"infile" description:"Input tarball"`
		Outfile string           `long:"outfile" description:"Output path, stdout is '-'"`
	} `positional-args:"yes" required:"yes"`
}

// NewCommand creates a new Command struct
func NewCommand() *Command {
	return &Command{
		configer: lxcconfig.LXCConfig,
		Stdout:   os.Stdout,
	}
}

// ShortDesc returns the command's short description
func (*Command) ShortDesc() string { return _description }

// LongDesc returns the command's long description
func (*Command) LongDesc() string { return _description }

// Execute executes lxcconfig Command
func (c *Command) Execute(args []string) (err error) {
	if len(args) != 0 {
		return errors.New("too many args")
	}

	rd, err := os.Open(string(c.PositionalArgs.Infile))
	if err != nil {
		return err
	}
	defer func() {
		err1 := rd.Close()
		if err == nil {
			err = err1
		}
	}()

	var out io.Writer
	outf := string(c.PositionalArgs.Outfile)
	if fname := string(c.PositionalArgs.Outfile); fname == "-" {
		out = c.Stdout
	} else {
		outf, err := os.Create(outf)
		if err != nil {
			return fmt.Errorf("create: %w", err)
		}
		defer func() {
			err1 := outf.Close()
			if err == nil {
				err = err1
			}
		}()
		out = outf
	}

	return c.configer(rd, out)
}
