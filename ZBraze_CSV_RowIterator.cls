public class ZBraze_CSV_RowIterator {
    
    private String data;
    private Integer index = 0;
    private String rowDelimiter = '\n';
    
    public ZBraze_CSV_RowIterator(String fileData, String delimiter)
    {
        data = fileData; 
        rowDelimiter = delimiter;
    }
    
    public Boolean hasNext()
    {
        return index < data.length() ? true : false;
    }
    public String next()
    {     
        Integer key = data.indexOf(rowDelimiter, index);
        
        if (key == -1)
            key = data.length();
        
        String row = data.subString(index, key);
        index = key + 1;
        return row;
    }
   
    
}