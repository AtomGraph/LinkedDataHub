"""The request sites of the client's stylesheets whose target is not built by ldh:href where they stand.

Every 'href' entry of a map under xsl/client.xsl and xsl/client/ is read. One that names a variable or a parameter is
followed to the nearest declaration above it with that name. A site whose expression, so followed, is a call of
ldh:href is the model's Target.href and is left out; the others are printed, one per line, as FILE<TAB>EXPRESSION,
sorted. `ldh-client sites` prints the same lines from LdhClient/Sites.lean, and the workflow diffs the two.

    python3 formal/client/sites.py src/main/webapp/static/com/atomgraph/linkeddatahub/xsl
"""
import glob
import re
import sys

root = sys.argv[1].rstrip('/')
files = [root + '/client.xsl'] + sorted(glob.glob(root + '/client/**/*.xsl', recursive=True))
rows = []


def expression(line, start):
    """The XPath expression from start to the comma or brace that ends it at depth zero, outside string literals."""
    depth, quote, k = 0, None, start
    while k < len(line):
        c = line[k]
        if quote:
            quote = None if c == quote else quote
        elif c in '\'"':
            quote = c
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            if depth == 0:
                break
            depth -= 1
        elif c == ',' and depth == 0:
            break
        k += 1
    return line[start:k].strip()


for f in files:
    lines = open(f, encoding='utf-8').read().split('\n')
    for i, line in enumerate(lines):
        for m in re.finditer(r"'href': ", line):
            expr = expression(line, m.end())
            resolved = expr
            v = re.fullmatch(r'\$([A-Za-z][\w.-]*)', expr)
            if v:
                for j in range(i, -1, -1):
                    d = re.search(r'name="%s"[^>]*select="([^"]*)"' % re.escape(v.group(1)), lines[j])
                    if d:
                        resolved = d.group(1)
                        break
            if not resolved.startswith('ldh:href('):
                rows.append(f[len(root) + 1:] + '\t' + expr)
print('\n'.join(sorted(rows)))
