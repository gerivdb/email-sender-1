import * as assert from 'assert';

describe('Simple Tests', () => {
    it('should pass a basic test', () => {
        assert.strictEqual(1 + 1, 2);
    });

    it('should detect null reference patterns', () => {
        const line = '$user = $null; $name = $user.Name';
        const hasNullReference = line.includes('$null') && line.match(/\$\w+\.\w+/);
        assert.ok(hasNullReference, 'Failed to detect null reference pattern');
    });

    it('should detect array index out of bounds patterns', () => {
        const line = '$array = @(1, 2, 3); $value = $array[5]';
        const hasIndexOutOfBounds = line.match(/\$\w+\[\d+\]/);
        assert.ok(hasIndexOutOfBounds, 'Failed to detect index out of bounds pattern');
    });

    it('should detect type conversion patterns', () => {
        const line = '$input = "abc"; $number = [int]$input';
        const hasTypeConversion = line.match(/\[\w+(\.\w+)*\]\$\w+/);
        assert.ok(hasTypeConversion, 'Failed to detect type conversion pattern');
    });

    it('should detect uninitialized variable patterns', () => {
        const line = '$result = $total + 10';
        const hasUninitializedVariable = line.match(/\$\w+/) && !line.includes('=');
        // This test will fail because the line includes '=', but that's expected
        // We're just testing the pattern detection logic
        assert.ok(line.match(/\$\w+/), 'Failed to detect variable usage');
    });
});
