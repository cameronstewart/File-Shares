---
name: file-share-visualization
description: Visualize file share analysis data including hierarchies, timelines, size distributions, permission matrices, and duplicate detection. Use when creating charts, graphs, visualizations, dashboards, or when the user mentions visualization, charts, graphs, or visual analysis.
allowed-tools: Read, Bash, Grep, Glob, Write
---

# File Share Data Visualization

Transform File-Shares toolkit CSV outputs into visual insights using charts, graphs, timelines, and hierarchical visualizations.

## Overview

The File-Shares toolkit generates CSV data perfect for visualization:
- **Hierarchical data** with ID/PARENTID relationships for tree visualizations
- **Temporal data** with creation, modification, access timestamps for timelines
- **Size data** for storage distribution analysis
- **Permission data** for access control matrices
- **Hash data** for duplicate detection visualizations

This skill teaches you how to visualize this data using multiple approaches.

## Visualization Tools Overview

| Tool | Best For | Complexity | Installation |
|------|----------|------------|--------------|
| **Excel** | Quick charts, pivot tables | Low | Built-in (Windows) |
| **PowerShell** | Automated reports, simple charts | Medium | Built-in |
| **Python** | Complex visualizations, automation | Medium-High | Requires install |
| **PowerBI** | Interactive dashboards | Medium | Free download |
| **Online Tools** | Quick one-time visualizations | Low | Web browser |

## Excel Visualizations

### Quick Start: Import and Visualize

**Step 1: Import CSV**
```powershell
# Generate data
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\FileShare" `
    -OutputPath "C:\analysis.csv"

# Open in Excel
Start-Process excel "C:\analysis.csv"
```

**Step 2: Create Pivot Table**
1. Select all data (Ctrl+A)
2. Insert → PivotTable
3. Drag fields to create summaries

### Visualization 1: File Type Distribution (Pie Chart)

**Objective:** Show percentage of files by extension.

**Steps:**
1. Create PivotTable from CSV data
2. Rows: Extension
3. Values: Count of Path
4. Insert → Pie Chart
5. Format: Show percentages

**Expected Output:** Pie chart showing `.docx` 35%, `.pdf` 25%, `.xlsx` 20%, etc.

### Visualization 2: Storage by Folder (Bar Chart)

**Objective:** Identify which folders consume most storage.

**Excel Formula Approach:**
```excel
# Add column: FolderName
=LEFT(A2, FIND("\", A2, FIND("\", A2)+1))

# Create PivotTable
Rows: FolderName
Values: Sum of Bytes
Sort: Descending by Bytes

# Insert → Bar Chart
```

**Expected Output:** Horizontal bar chart showing top folders by size.

### Visualization 3: File Growth Over Time (Line Chart)

**Objective:** Show file creation trends over time.

**Steps:**
1. Create PivotTable
2. Rows: CreationTime (grouped by Month/Year)
3. Values: Count of Path
4. Insert → Line Chart

**Expected Output:** Line graph showing file creation trends.

### Visualization 4: Permission Matrix (Heatmap)

**Objective:** Visualize who has access to what.

**Steps:**
```powershell
# Generate permission data
.\Folder Permissions.ps1 -FolderPath "C:\Shares" -OutputPath "permissions.csv"
```

1. Create PivotTable from permissions.csv
2. Rows: Path
3. Columns: ADGroupOrUser
4. Values: FileSystemRights
5. Conditional Formatting → Color Scales

**Expected Output:** Heatmap showing access patterns.

## PowerShell Visualizations

### Simple Console Charts

**Bar Chart in Console:**
```powershell
# Load data
$data = Import-Csv "analysis.csv"

# Count by extension
$stats = $data | Where-Object {$_.ISDIR -eq "False"} |
    Group-Object Extension |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Select-Object -First 10

# Display as text bar chart
foreach ($item in $stats) {
    $bar = "█" * [math]::Round($item.Count / 100)
    Write-Host ("{0,-10} {1,6} {2}" -f $item.Name, $item.Count, $bar)
}
```

**Output:**
```
.docx       1234 ████████████
.pdf         987 █████████
.xlsx        654 ██████
```

### HTML Report with Charts

**Generate Interactive HTML Report:**
```powershell
# Load data
$data = Import-Csv "analysis.csv"
$files = $data | Where-Object {$_.ISDIR -eq "False"}

# Calculate statistics
$totalFiles = $files.Count
$totalSize = ($files | Measure-Object -Property Bytes -Sum).Sum
$totalSizeGB = [math]::Round($totalSize / 1GB, 2)

# File type distribution
$typeStats = $files | Group-Object Extension |
    Select-Object @{N='Extension';E={$_.Name}},
                  @{N='Count';E={$_.Count}},
                  @{N='Percentage';E={[math]::Round(($_.Count / $totalFiles) * 100, 2)}} |
    Sort-Object Count -Descending |
    Select-Object -First 10

# Generate HTML
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>File Share Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        .stat-box {
            display: inline-block;
            background: #3498db;
            color: white;
            padding: 20px;
            margin: 10px;
            border-radius: 5px;
        }
        .stat-value { font-size: 32px; font-weight: bold; }
        .stat-label { font-size: 14px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #3498db; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .bar { background: #3498db; height: 20px; display: inline-block; }
    </style>
</head>
<body>
    <h1>File Share Analysis Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>

    <div>
        <div class="stat-box">
            <div class="stat-value">$totalFiles</div>
            <div class="stat-label">Total Files</div>
        </div>
        <div class="stat-box">
            <div class="stat-value">$totalSizeGB GB</div>
            <div class="stat-label">Total Size</div>
        </div>
    </div>

    <h2>File Type Distribution</h2>
    <table>
        <tr><th>Extension</th><th>Count</th><th>Percentage</th><th>Visual</th></tr>
"@

foreach ($type in $typeStats) {
    $barWidth = $type.Percentage * 3
    $html += @"
        <tr>
            <td>$($type.Extension)</td>
            <td>$($type.Count)</td>
            <td>$($type.Percentage)%</td>
            <td><div class="bar" style="width: ${barWidth}px;"></div></td>
        </tr>
"@
}

$html += @"
    </table>
</body>
</html>
"@

# Save and open
$html | Out-File "report.html" -Encoding UTF8
Start-Process "report.html"
```

**Expected Output:** Interactive HTML report with statistics and bar charts.

## Python Visualizations

### Setup

**Install required packages:**
```bash
pip install pandas matplotlib seaborn plotly networkx
```

### Visualization 1: Storage Treemap

**Show hierarchical storage distribution:**

```python
import pandas as pd
import plotly.express as px

# Load data
df = pd.read_csv('analysis.csv')

# Filter to files only
files = df[df['ISDIR'] == False].copy()

# Extract folder from path
files['Folder'] = files['Path'].str.rsplit('\\', n=1).str[0]

# Group by folder
folder_stats = files.groupby('Folder').agg({
    'Bytes': 'sum',
    'Path': 'count'
}).reset_index()
folder_stats.columns = ['Folder', 'Size', 'FileCount']

# Create treemap
fig = px.treemap(folder_stats,
                 path=['Folder'],
                 values='Size',
                 title='Storage Distribution by Folder',
                 color='Size',
                 color_continuous_scale='Blues')

fig.show()
# Save
fig.write_html('storage_treemap.html')
```

**Expected Output:** Interactive treemap showing folder sizes.

### Visualization 2: Timeline Heatmap

**Show file activity over time:**

```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load data
df = pd.read_csv('analysis.csv')

# Parse dates
df['CreationTime'] = pd.to_datetime(df['CreationTime'])
df['Date'] = df['CreationTime'].dt.date
df['Hour'] = df['CreationTime'].dt.hour

# Create heatmap data
heatmap_data = df.groupby(['Date', 'Hour']).size().reset_index(name='Count')
heatmap_pivot = heatmap_data.pivot(index='Hour', columns='Date', values='Count').fillna(0)

# Create heatmap
plt.figure(figsize=(15, 8))
sns.heatmap(heatmap_pivot, cmap='YlOrRd', cbar_kws={'label': 'Files Created'})
plt.title('File Creation Activity Heatmap')
plt.xlabel('Date')
plt.ylabel('Hour of Day')
plt.tight_layout()
plt.savefig('activity_heatmap.png', dpi=300)
plt.show()
```

**Expected Output:** Heatmap showing when files were created.

### Visualization 3: File Size Distribution

**Show file size distribution with histogram:**

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load data
df = pd.read_csv('analysis.csv')
files = df[df['ISDIR'] == False].copy()

# Convert bytes to MB
files['SizeMB'] = files['Bytes'] / (1024 * 1024)

# Create histogram
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

# Linear scale
ax1.hist(files['SizeMB'], bins=50, color='#3498db', edgecolor='black')
ax1.set_xlabel('File Size (MB)')
ax1.set_ylabel('Frequency')
ax1.set_title('File Size Distribution (Linear Scale)')
ax1.grid(True, alpha=0.3)

# Log scale (better for wide range of sizes)
ax2.hist(files['SizeMB'], bins=50, color='#e74c3c', edgecolor='black')
ax2.set_xlabel('File Size (MB)')
ax2.set_ylabel('Frequency')
ax2.set_title('File Size Distribution (Log Scale)')
ax2.set_yscale('log')
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('size_distribution.png', dpi=300)
plt.show()
```

**Expected Output:** Dual histogram showing file size patterns.

### Visualization 4: Duplicate Detection Network

**Visualize duplicate files as network graph:**

```python
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

# Load data with hashes
df = pd.read_csv('analysis_with_hashes.csv')

# Find duplicates (files with same hash)
files_with_hash = df[df['SHA256'].notna() & (df['SHA256'] != '')].copy()
duplicates = files_with_hash[files_with_hash.duplicated('SHA256', keep=False)]

# Create network graph
G = nx.Graph()

# Group by hash
for hash_value, group in duplicates.groupby('SHA256'):
    files = group['Path'].tolist()

    # Add nodes
    for file in files:
        G.add_node(file, label=file.split('\\')[-1])

    # Add edges between duplicates
    for i, file1 in enumerate(files):
        for file2 in files[i+1:]:
            G.add_edge(file1, file2, hash=hash_value)

# Draw graph
plt.figure(figsize=(20, 20))
pos = nx.spring_layout(G, k=0.5, iterations=50)

# Draw nodes
nx.draw_networkx_nodes(G, pos, node_color='#3498db',
                       node_size=500, alpha=0.8)

# Draw edges
nx.draw_networkx_edges(G, pos, alpha=0.3)

# Draw labels
labels = {node: data['label'] for node, data in G.nodes(data=True)}
nx.draw_networkx_labels(G, pos, labels, font_size=8)

plt.title(f'Duplicate Files Network ({len(G.nodes())} files, {len(G.edges())} duplicate relationships)',
          fontsize=16)
plt.axis('off')
plt.tight_layout()
plt.savefig('duplicates_network.png', dpi=300, bbox_inches='tight')
plt.show()

print(f"Found {len(G.nodes())} duplicate files")
print(f"Total duplicate groups: {duplicates['SHA256'].nunique()}")
```

**Expected Output:** Network graph showing duplicate file relationships.

### Visualization 5: Permission Sunburst Chart

**Hierarchical permission visualization:**

```python
import pandas as pd
import plotly.express as px

# Load permission data
df = pd.read_csv('permissions.csv')

# Create hierarchy: Path → User → Rights
df['PathShort'] = df['Path'].str.split('\\').str[-1]

# Create sunburst
fig = px.sunburst(df,
                  path=['PathShort', 'ADGroupOrUser', 'FileSystemRights'],
                  title='Permission Hierarchy',
                  color='AccessControlType',
                  color_discrete_map={'Allow': '#27ae60', 'Deny': '#e74c3c'})

fig.update_traces(textinfo='label+percent parent')
fig.show()
fig.write_html('permissions_sunburst.html')
```

**Expected Output:** Interactive sunburst showing permission hierarchy.

## Forensic Timeline Visualizations

### Timeline with Event Types

**Visualize file activity timeline for forensic analysis:**

```python
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime

# Load forensic timeline
df = pd.read_csv('forensic_timeline.csv')

# Parse timestamps
df['CreationTime'] = pd.to_datetime(df['CreationTime'])
df['LastWriteTime'] = pd.to_datetime(df['LastWriteTime'])
df['LastAccessTime'] = pd.to_datetime(df['LastAccessTime'])

# Create unified timeline
events = []

for _, row in df.iterrows():
    # Creation event
    events.append({
        'Time': row['CreationTime'],
        'Event': 'Created',
        'File': row['Name'],
        'Path': row['Path']
    })

    # Modification event (if different)
    if row['LastWriteTime'] != row['CreationTime']:
        events.append({
            'Time': row['LastWriteTime'],
            'Event': 'Modified',
            'File': row['Name'],
            'Path': row['Path']
        })

    # Access event (if different)
    if row['LastAccessTime'] not in [row['CreationTime'], row['LastWriteTime']]:
        events.append({
            'Time': row['LastAccessTime'],
            'Event': 'Accessed',
            'File': row['Name'],
            'Path': row['Path']
        })

timeline_df = pd.DataFrame(events).sort_values('Time')

# Create timeline visualization
fig = go.Figure()

colors = {'Created': '#3498db', 'Modified': '#e67e22', 'Accessed': '#2ecc71'}

for event_type in ['Created', 'Modified', 'Accessed']:
    data = timeline_df[timeline_df['Event'] == event_type]

    fig.add_trace(go.Scatter(
        x=data['Time'],
        y=data['File'],
        mode='markers',
        name=event_type,
        marker=dict(size=10, color=colors[event_type]),
        text=data['Path'],
        hovertemplate='<b>%{y}</b><br>Time: %{x}<br>Path: %{text}<extra></extra>'
    ))

fig.update_layout(
    title='Forensic File Activity Timeline',
    xaxis_title='Time',
    yaxis_title='File',
    height=800,
    hovermode='closest'
)

fig.show()
fig.write_html('forensic_timeline.html')
```

**Expected Output:** Interactive timeline showing file events during incident window.

## Dashboard Creation

### PowerBI Dashboard

**Steps:**
1. Open Power BI Desktop
2. Get Data → Text/CSV → Select your analysis.csv
3. Create visualizations:
   - Card: Total Files, Total Size
   - Pie Chart: File types
   - Bar Chart: Top 10 folders by size
   - Line Chart: Files created over time
   - Table: Largest files

4. Add slicers for filtering:
   - Date range
   - File extension
   - Folder path

5. Publish to Power BI Service for sharing

### Jupyter Notebook Dashboard

**Create interactive notebook:**

```python
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# Load data
df = pd.read_csv('analysis.csv')
files = df[df['ISDIR'] == False].copy()

# Create dashboard with subplots
fig = make_subplots(
    rows=2, cols=2,
    subplot_titles=('File Type Distribution', 'Size by Folder',
                    'Creation Timeline', 'Top 20 Largest Files'),
    specs=[[{'type': 'pie'}, {'type': 'bar'}],
           [{'type': 'scatter'}, {'type': 'bar'}]]
)

# 1. File type pie chart
type_stats = files.groupby('Extension').size().reset_index(name='Count')
fig.add_trace(
    go.Pie(labels=type_stats['Extension'], values=type_stats['Count']),
    row=1, col=1
)

# 2. Size by folder bar chart
files['Folder'] = files['Path'].str.rsplit('\\', n=1).str[0]
folder_stats = files.groupby('Folder')['Bytes'].sum().sort_values(ascending=True).tail(10)
fig.add_trace(
    go.Bar(x=folder_stats.values, y=folder_stats.index, orientation='h'),
    row=1, col=2
)

# 3. Creation timeline
files['CreationTime'] = pd.to_datetime(files['CreationTime'])
daily_counts = files.groupby(files['CreationTime'].dt.date).size()
fig.add_trace(
    go.Scatter(x=daily_counts.index, y=daily_counts.values, mode='lines+markers'),
    row=2, col=1
)

# 4. Largest files
largest = files.nlargest(20, 'Bytes')
largest['SizeMB'] = largest['Bytes'] / (1024*1024)
largest['FileName'] = largest['Path'].str.split('\\').str[-1]
fig.add_trace(
    go.Bar(x=largest['SizeMB'], y=largest['FileName'], orientation='h'),
    row=2, col=2
)

fig.update_layout(height=800, showlegend=False, title_text="File Share Analysis Dashboard")
fig.show()
fig.write_html('dashboard.html')
```

**Expected Output:** Comprehensive 4-panel dashboard.

## Hierarchical Tree Visualizations

### D3.js Interactive Tree

**Generate HTML with D3.js tree visualization:**

```powershell
# Load data
$data = Import-Csv "analysis.csv"

# Generate JSON for D3.js (simplified example)
# In practice, you'd build this programmatically based on ID/PARENTID relationships

$html = @"
<!DOCTYPE html>
<html>
<head>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        .node circle { fill: #3498db; stroke: #2c3e50; stroke-width: 2px; }
        .node text { font: 12px sans-serif; }
        .link { fill: none; stroke: #ccc; stroke-width: 2px; }
    </style>
</head>
<body>
    <div id="tree"></div>
    <script>
        // Load and render tree visualization
        // (Simplified - actual implementation would parse CSV ID/PARENTID)
    </script>
</body>
</html>
"@

$html | Out-File "tree_visualization.html"
```

## Quick Visualization Scripts

### One-Liner Visualizations

**Top 10 largest files:**
```powershell
Import-Csv analysis.csv |
    Where-Object {$_.ISDIR -eq "False"} |
    Sort-Object {[int64]$_.Bytes} -Descending |
    Select-Object -First 10 Name, @{N='SizeMB';E={[math]::Round($_.Bytes/1MB,2)}} |
    Format-Table -AutoSize
```

**File type summary:**
```powershell
Import-Csv analysis.csv |
    Where-Object {$_.ISDIR -eq "False"} |
    Group-Object Extension |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize
```

**Duplicate file report:**
```powershell
Import-Csv analysis_with_hashes.csv |
    Where-Object {$_.SHA256 -ne ""} |
    Group-Object SHA256 |
    Where-Object {$_.Count -gt 1} |
    ForEach-Object { $_.Group | Select-Object Path, Bytes, SHA256 } |
    Format-Table -AutoSize
```

## Online Visualization Tools

### Quick Web-Based Visualizations

**Tools:**
1. **RAWGraphs** (https://rawgraphs.io)
   - Upload CSV directly
   - Create treemaps, sunbursts, circle packing
   - No installation required

2. **Plotly Chart Studio** (https://chart-studio.plotly.com)
   - Upload CSV
   - Create interactive charts
   - Share visualizations

3. **Google Sheets**
   - Upload CSV to Google Drive
   - Open with Google Sheets
   - Insert → Chart

## Best Practices

### Data Preparation

**Clean data before visualizing:**
```powershell
$data = Import-Csv "analysis.csv"

# Remove null values
$clean = $data | Where-Object {$_.Bytes -ne $null -and $_.Bytes -ne ""}

# Convert data types
$clean | ForEach-Object {
    $_.Bytes = [int64]$_.Bytes
    $_.CreationTime = [datetime]$_.CreationTime
}

# Export cleaned data
$clean | Export-Csv "analysis_clean.csv" -NoTypeInformation
```

### Performance Tips

**For large datasets:**
1. **Filter before visualizing** - Show top 100, not all million files
2. **Aggregate data** - Group by folder instead of showing individual files
3. **Sample data** - Use random sampling for patterns
4. **Use appropriate tools** - Python/PowerBI for >100K rows, Excel for <10K rows

### Color Schemes

**Use colorblind-friendly palettes:**
```python
# Good palette (colorblind-safe)
colors = ['#0173b2', '#de8f05', '#029e73', '#cc78bc', '#ca9161', '#fbafe4']

# For sequential data (light to dark)
sns.color_palette("Blues", n_colors=10)

# For diverging data (red-white-blue)
sns.color_palette("RdBu", n_colors=11)
```

## Example Use Cases

### Use Case 1: Storage Audit Report

**Objective:** Show management where storage is consumed.

**Visualizations:**
1. Treemap of storage by folder
2. Pie chart of file types
3. Bar chart of top 20 largest files
4. Growth timeline

### Use Case 2: Compliance Dashboard

**Objective:** Show permission compliance for audit.

**Visualizations:**
1. Permission matrix (who has access)
2. Sunburst of permission hierarchy
3. Table of overly-permissive access
4. Heatmap of permission changes over time

### Use Case 3: Forensic Investigation

**Objective:** Present timeline of file activity during incident.

**Visualizations:**
1. Activity timeline (created/modified/accessed)
2. Network graph of file relationships
3. Heatmap of activity by time of day
4. Table of suspicious files (created during incident window)

## Get Help

For data from File-Shares scripts:
```powershell
# Generate data for visualization
Get-Help ".\FileNamePath Export with Hash.ps1" -Examples
Get-Help ".\Folder Permissions.ps1" -Examples
```

## Resources

**Visualization Libraries:**
- **Plotly**: https://plotly.com/python/
- **Matplotlib**: https://matplotlib.org/
- **Seaborn**: https://seaborn.pydata.org/
- **D3.js**: https://d3js.org/

**PowerBI:**
- Power BI Desktop: https://powerbi.microsoft.com/desktop/

**Online Tools:**
- RAWGraphs: https://rawgraphs.io
- Chart Studio: https://chart-studio.plotly.com

## Next Steps

After creating visualizations:
1. **Share insights** - Export to PDF/HTML for distribution
2. **Automate reports** - Schedule PowerShell scripts to generate weekly dashboards
3. **Iterate** - Refine visualizations based on stakeholder feedback
4. **Combine skills** - Use with other File-Shares skills for comprehensive analysis
