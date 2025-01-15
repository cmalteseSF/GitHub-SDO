global class StardustDRFunctions implements Callable
{
    /*
        inputs - arguments - List<Object> of passed in arguments
        output - result - The result of the Function being called. Supports single Object values, List<Object> or Map<String, Object>
    */
    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input   = (Map<String, Object>)args.get('input');
        Map<String, Object> output  = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }
    global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options)
    {
        // SUM Returns a single value
        if (methodName == 'sum')
        {
            List<Object> arguments = (List<Object>)inputs.get('arguments');
            output.put('result', sum(arguments));
        }

        else if (methodName == 'len')
        {
            List<Object> arguments = (List<Object>)inputs.get('arguments');
            output.put('result', len(arguments));
        }

        return true;
    }

    // ********************************************************
    // sum
    Double sum(List<Object> arguments)
    {
        Double result = 0;
        for(Object token : arguments)
        {
            if (token != null)
            {
                result += (Double)token;
            }
        }
        return result;
    }

    // ********************************************************
    // length
    Integer len(List<Object> arguments)
    {
        Integer result = 0;
        String  linenumber = (String)arguments[0];
        result = linenumber.length();
        return result; 

    }



}