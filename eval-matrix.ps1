# development\scripts\planning\apply-evaluation-matrix.ps1
# Script to apply evaluation matrix to skills and generate a report

# Parameters
param (
    [string]$ExpertiseFile = "development\data\planning\expertise-levels.md",
    [string]$SkillsFile = "development\data\planning\skills-list.md",
    [string]$OutputFile = "development\data\planning\skills-evaluation.md"
)

# Evaluation criteria definition
$EvaluationCriteria = @(
    @{ Name = "Complexity"; Weight = 0.3; Description = "Task complexity level" },
    @{ Name = "Supervision"; Weight = 0.25; Description = "Level of supervision needed" },
    @{ Name = "ProblemSolving"; Weight = 0.25; Description = "Problem-solving capability" },
    @{ Name = "Impact"; Weight = 0.2; Description = "Impact on project outcomes" }
)

# Expertise levels
$ExpertiseLevels = @{
    "Beginner"     = 1
    "Intermediate" = 2
    "Advanced"     = 3
    "Expert"       = 4
}

# Function to parse Markdown file
function Parse-MarkdownFile {
    param ([string]$FilePath)

    $content = Get-Content -Path $FilePath -Raw
    $skills = @()

    # Simple regex-based parsing for skills (assuming markdown structure)
    $pattern = '###\s(?<Category>[^\n]+)\n(?<Details>(?:.|\n)*?)(?=\n###|\z)'
    $matches = [regex]::Matches($content, $pattern)

    foreach ($match in $matches) {
        $category = $match.Groups['Category'].Value
        $details = $match.Groups['Details'].Value -split '\n'

        foreach ($line in $details) {
            if ($line -match '-\s(?<Skill>[^\(]+)\((?<Level>[^\)]+)\):\s(?<Justification>.+)') {
                $skills += @{
                    Category      = $category.Trim()
                    Skill         = $matches.Groups['Skill'].Value.Trim()
                    Level         = $matches.Groups['Level'].Value.Trim()
                    Justification = $matches.Groups['Justification'].Value.Trim()
                }
            }
        }
    }

    return $skills
}

# Function to evaluate skill
function Evaluate-Skill {
    param (
        [hashtable]$Skill,
        [array]$Criteria
    )

    $evaluation = @{}
    $totalScore = 0

    foreach ($criterion in $Criteria) {
        # Simulated evaluation logic (in practice, this would use more complex rules)
        $score = switch ($Skill.Level) {
            "Beginner" { 1 }
            "Intermediate" { 2 }
            "Advanced" { 3 }
            "Expert" { 4 }
            default { 1 }
        }

        $weightedScore = $score * $criterion.Weight
        $totalScore += $weightedScore
        $evaluation[$criterion.Name] = @{
            Score         = $score
            WeightedScore = $weightedScore
        }
    }

    return @{
        Evaluation = $evaluation
        TotalScore = [math]::Round($totalScore, 2)
        FinalLevel = switch ([math]::Floor($totalScore)) {
            1 { "Beginner" }
            2 { "Intermediate" }
            3 { "Advanced" }
            4 { "Expert" }
            default { "Beginner" }
        }
    }
}

# Function to generate Markdown report
function Generate-Report {
    param (
        [array]$Evaluations,
        [string]$OutputPath
    )

    $levelDistribution = @{
        Beginner     = 0
        Intermediate = 0
        Advanced     = 0
        Expert       = 0
    }

    # Calculate distribution
    foreach ($eval in $Evaluations) {
        $levelDistribution[$eval.FinalLevel]++
    }

    $report = @"
# Skills Evaluation Report

## Table of Contents
- [Methodology](#methodology)
- [Evaluated Skills](#evaluated-skills)
- [Summary](#summary)
- [Recommendations](#recommendations)

## Methodology
This evaluation uses a weighted criteria matrix to assess skills based on:
$($EvaluationCriteria | ForEach-Object { "- $($_.Name) ($($_.Weight*100)%): $($_.Description)" } | Join-String -Separator "`n")

## Evaluated Skills
| Skill | Category | Complexity | Supervision | Problem Solving | Impact | Total Score | Final Level |
|-------|----------|------------|-------------|-----------------|--------|-------------|-------------|
$($Evaluations | ForEach-Object {
    "| $($_.Skill) | $($_.Category) | $($_.Evaluation.Complexity.Score) | $($_.Evaluation.Supervision.Score) | $($_.Evaluation.ProblemSolving.Score) | $($_.Evaluation.Impact.Score) | $($_.TotalScore) | $($_.FinalLevel) |"
} | Join-String -Separator "`n")

## Summary
- Beginner: $($levelDistribution.Beginner) skills
- Intermediate: $($levelDistribution.Intermediate) skills
- Advanced: $($levelDistribution.Advanced) skills
- Expert: $($levelDistribution.Expert) skills

## Recommendations
Based on the evaluation:
- Focus training on Beginner/Intermediate skills
- Allocate senior resources to Expert-level tasks
- Review skills with low scores for potential automation
"@

    Set-Content -Path $OutputPath -Value $report
}

# Main execution
try {
    # Validate input files
    if (-not (Test-Path $ExpertiseFile)) { throw "Expertise file not found" }
    if (-not (Test-Path $SkillsFile)) { throw "Skills file not found" }

    # Parse input files
    $skills = Parse-MarkdownFile -FilePath $SkillsFile

    # Evaluate skills
    $evaluations = @()
    foreach ($skill in $skills) {
        $evalResult = Evaluate-Skill -Skill $skill -Criteria $EvaluationCriteria
        $evaluations += @{
            Skill      = $skill.Skill
            Category   = $skill.Category
            Evaluation = $evalResult.Evaluation
            TotalScore = $evalResult.TotalScore
            FinalLevel = $evalResult.FinalLevel
        }
    }

    # Generate report
    Generate-Report -Evaluations $evaluations -OutputPath $OutputFile

    Write-Host "Evaluation completed. Report generated at: $OutputFile"
} catch {
    Write-Error "Error: $_"
    exit 1
}
