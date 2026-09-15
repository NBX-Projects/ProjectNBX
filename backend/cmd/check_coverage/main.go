package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	f, err := os.Open("coverage/lcov.info")
	if err != nil {
		fmt.Printf("Erro ao abrir coverage/lcov.info: %v\n", err)
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	lcovFiles := make(map[string]struct{ covered, total int })
	var currentFile string
	var covered, total int

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "SF:") {
			currentFile = filepath.Clean(line[3:])
			covered, total = 0, 0
		} else if strings.HasPrefix(line, "LF:") {
			_, _ = fmt.Sscanf(line[3:], "%d", &total)
		} else if strings.HasPrefix(line, "LH:") {
			_, _ = fmt.Sscanf(line[3:], "%d", &covered)
			lcovFiles[currentFile] = struct{ covered, total int }{covered: covered, total: total}
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Printf("Erro durante a leitura de coverage/lcov.info: %v\n", err)
	}

	var libFiles []string
	_ = filepath.Walk("lib", func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() && strings.HasSuffix(path, ".dart") {
			libFiles = append(libFiles, filepath.Clean(path))
		}
		return nil
	})

	fmt.Println("=== FLUTTER COVERAGE BREAKDOWN ===")
	var totalCovered, totalLines int
	var notInLcov []string

	for _, lib := range libFiles {
		stats, found := lcovFiles[lib]
		if !found {
			matched := false
			for k, v := range lcovFiles {
				if strings.HasSuffix(k, lib) || strings.HasSuffix(lib, k) {
					stats = v
					found = true
					matched = true
					break
				}
			}
			if !matched {
				notInLcov = append(notInLcov, lib)
				continue
			}
		}
		pct := 0.0
		if stats.total > 0 {
			pct = float64(stats.covered) / float64(stats.total) * 100
		}
		totalCovered += stats.covered
		totalLines += stats.total
		fmt.Printf("%6.1f%% (%3d/%3d) %s\n", pct, stats.covered, stats.total, lib)
	}

	fmt.Println("\n=== LIB FILES NOT IN LCOV (0% COVERED) ===")
	for _, f := range notInLcov {
		fmt.Printf("  - %s\n", f)
	}

	overall := 0.0
	if totalLines > 0 {
		overall = float64(totalCovered) / float64(totalLines) * 100
	}
	fmt.Printf("\nOverall Coverage (for files tested): %.2f%% (%d/%d)\n", overall, totalCovered, totalLines)

	// Backend coverage
	bf, err := os.Open("backend/coverage.out")
	if err != nil {
		fmt.Printf("Aviso: backend/coverage.out não encontrado (%v)\n", err)
		return
	}
	defer bf.Close()

	bScanner := bufio.NewScanner(bf)
	var bTotal, bCovered int
	var bExclTotal, bExclCovered int

	for bScanner.Scan() {
		line := strings.TrimSpace(bScanner.Text())
		if strings.HasPrefix(line, "mode:") {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) != 3 {
			continue
		}
		var stmts, count int
		_, _ = fmt.Sscanf(parts[1], "%d", &stmts)
		_, _ = fmt.Sscanf(parts[2], "%d", &count)

		bTotal += stmts
		if count > 0 {
			bCovered += stmts
		}

		isExcluded := strings.Contains(parts[0], "postgres_repo.go") ||
			strings.Contains(parts[0], "db.go") ||
			strings.Contains(parts[0], "migrator.go") ||
			strings.Contains(parts[0], "cmd/")

		if !isExcluded {
			bExclTotal += stmts
			if count > 0 {
				bExclCovered += stmts
			}
		}
	}

	if err := bScanner.Err(); err != nil {
		fmt.Printf("Erro durante a leitura de backend/coverage.out: %v\n", err)
	}

	fmt.Printf("\n=== BACKEND GO COVERAGE ===\n")
	if bTotal > 0 {
		fmt.Printf("Raw Total: %.2f%% (%d/%d)\n", float64(bCovered)/float64(bTotal)*100, bCovered, bTotal)
	}
	if bExclTotal > 0 {
		fmt.Printf("Excluding postgres_repo/db/migrator/cmd: %.2f%% (%d/%d)\n", float64(bExclCovered)/float64(bExclTotal)*100, bExclCovered, bExclTotal)
	}
}
