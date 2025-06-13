package commitinterceptor

import "regexp"

// DebugRegex provides debug information for regex matching
func DebugRegex(pattern string, input string) (bool, []string) {
	r, err := regexp.Compile(pattern)
	if err != nil {
		return false, nil
	}

	matches := r.FindStringSubmatch(input)
	return len(matches) > 0, matches
}
